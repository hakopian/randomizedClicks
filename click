import random
from enum import Enum
import sys
import math
import time

SRL_GAUSS_CUTOFF = 4.0


class EWaitDir(Enum):
    wdLeft = 0
    wdMean = 1
    wdRight = 2


def nzRandom():
    if random.random() > 0.5:
        return max(random.random(), 1.0e-4900) if sys.float_info.max == 1.18973149535723176502e+4932 else max(
            random.random(), 1.0e-320)
    else:
        return max(random.random(), 1.0e-320)


def gauss_rand(mean, dev):
    len = dev * math.sqrt(-2 * math.log(nzRandom()))
    result = mean + len * math.cos(2 * math.pi * random.random())
    return result


def truncated_gauss(left=0, right=1, cutoff=0):
    if cutoff <= 0:
        cutoff = SRL_GAUSS_CUTOFF

    result = cutoff + 1
    while result >= cutoff:
        result = abs(math.sqrt(-2 * math.log(nzRandom())) * math.cos(2 * math.pi * random.random()))

    result = result / cutoff * (right - left) + left
    return result


def truncated_gauss_int(left=0, right=1, cutoff=0):
    return int(truncated_gauss(left, right, cutoff))


def skewed_rand(mode, lo, hi, cutoff=0):
    if cutoff <= 0:
        cutoff = SRL_GAUSS_CUTOFF

    top = lo
    if random.random() * (hi - lo) > mode - lo:
        top = hi

    result = cutoff + 1
    while result >= cutoff:
        result = abs(math.sqrt(-2 * math.log(nzRandom())) * math.cos(2 * math.pi * random.random()))

    result = result / cutoff * (top - mode) + mode
    return result


def skewed_rand_int(mode, lo, hi, cutoff=0):
    return int(skewed_rand(mode * 1.00, lo * 1.00, hi * 1.00, cutoff))


def normal_range_float(min_val, max_val, cutoff=0):
    if cutoff <= 0:
        cutoff = SRL_GAUSS_CUTOFF

    mid_val = (max_val + min_val) / 2.0

    choice = random.randint(0, 1)
    if choice == 0:
        result = mid_val + truncated_gauss(0, (max_val - min_val) / 2, cutoff)
    else:
        result = mid_val - truncated_gauss(0, (max_val - min_val) / 2, cutoff)

    return result


def normal_range_int(min_val, max_val, cutoff=0):
    if cutoff <= 0:
        cutoff = SRL_GAUSS_CUTOFF

    mid_val = (max_val + min_val) / 2.0

    choice = random.randint(0, 1)
    if choice == 0:
        result = round(mid_val + truncated_gauss(0, (max_val - min_val) / 2, cutoff))
    else:
        result = round(mid_val - truncated_gauss(0, (max_val - min_val) / 2, cutoff))

    return result


class TPoint:
    def __init__(self, x=0, y=0):
        self.x = x
        self.y = y


class TBox:
    def __init__(self, left=0, top=0, right=0, bottom=0):
        self.left = left
        self.top = top
        self.right = right
        self.bottom = bottom


def random_point(mean, max_rad, cutoff=0):
    result = TPoint()
    result.x = normal_range_int(mean.x - max_rad, mean.x + max_rad, cutoff)
    result.y = normal_range_int(mean.y - max_rad, mean.y + max_rad, cutoff)
    return result


def random_point_bounds(bounds, cutoff=0):
    result = TPoint()
    result.x = normal_range_int(bounds.x1, bounds.x2, cutoff)
    result.y = normal_range_int(bounds.y1, bounds.y2, cutoff)
    return result


class TRectangle:
    def __init__(self, top, right, bottom, left):
        self.Top = top
        self.Right = right
        self.Bottom = bottom
        self.Left = left


def random_point_rectangle(rect, cutoff=0):
    a = math.atan2(rect.Left.y - rect.Top.y, rect.Left.x - rect.Top.x)
    x = (rect.Top.x + rect.Right.x + rect.Bottom.x + rect.Left.x) / 4
    y = (rect.Top.y + rect.Right.y + rect.Bottom.y + rect.Left.y) / 4
    x1 = x - math.hypot(rect.Left.y - rect.Top.y, rect.Left.x - rect.Top.x) / 2
    y1 = y - math.hypot(rect.Left.y - rect.Bottom.y, rect.Left.x - rect.Bottom.x) / 2
    x2 = x + math.hypot(rect.Left.y - rect.Top.y, rect.Left.x - rect.Top.x) / 2
    y2 = y + math.hypot(rect.Left.y - rect.Bottom.y, rect.Left.x - rect.Bottom.x) / 2

    result = TPoint()
    result.x = round(normal_range_int(x1 + 1, x2 - 1, cutoff))
    result.y = round(normal_range_int(y1 + 1, y2 - 1, cutoff))

    x_mid = (x2 + x1) / 2 + random.random() - 0.5
    y_mid = (y2 + y1) / 2 + random.random() - 0.5
    result = rotate_point(result, a, x_mid, y_mid)

    return result


def rotate_point(point, angle, pivot_x, pivot_y):
    rotated_x = math.cos(angle) * (point.x - pivot_x) - math.sin(angle) * (point.y - pivot_y) + pivot_x
    rotated_y = math.sin(angle) * (point.x - pivot_x) + math.cos(angle) * (point.y - pivot_y) + pivot_y
    return TPoint(round(rotated_x), round(rotated_y))


def random_point_ex(from_point, box, force=0.35):
    p = TPoint(from_point.x, from_point.y)
    if p.x < box.x1:
        p.x = box.x1
    elif p.x > box.x2:
        p.x = box.x2
    if p.y < box.y1:
        p.y = box.y1
    elif p.y > box.y2:
        p.y = box.y2

    c = TPoint((box.x2 + box.x1) // 2, (box.y2 + box.y1) // 2)
    r = math.hypot(p.x - c.x, p.y - c.y) * force
    x = math.atan2(c.y - p.y, c.x - p.x)
    p.x += round(math.cos(x) * r)
    p.y += round(math.sin(x) * r)


    result = TPoint()
    result.x = round(skewed_rand(p.x, box.x1, box.x2, SRL_GAUSS_CUTOFF))
    result.y = round(skewed_rand(p.y, box.y1, box.y2, SRL_GAUSS_CUTOFF))

    return result


def dist_to_line_ex(pt, sA, sB, nearest):
    nearest.x = sA.x
    nearest.y = sA.y
    dx = sB.x - sA.x
    dy = sB.y - sA.y
    d = dx * dx + dy * dy

    if d == 0:
        return math.hypot(pt.x - sA.x, pt.y - sA.y)

    f = ((pt.x - sA.x) * dx + (pt.y - sA.y) * dy) / d

    if f < 0:
        return math.hypot(pt.x - sA.x, pt.y - sA.y)
    if f > 1:
        nearest.x = sB.x
        nearest.y = sB.y
        return math.hypot(pt.x - sB.x, pt.y - sB.y)

    nearest.x = round(sA.x + f * dx)
    nearest.y = round(sA.y + f * dy)

    return math.hypot(pt.x - nearest.x, pt.y - nearest.y)


def rowp(from_point, box, force=-0.9, smoothness=math.pi/12):
    if isinstance(box, TBox):
        rect = TRectangle(box.left, box.top, box.right, box.bottom)
    else:
        rect = box

    p = random_point(rect, SRL_GAUSS_CUTOFF / 1.5)
    e = nearest_edge_to(p, rect)

    dist = math.hypot(p.x - e.x, p.y - e.y)
    t = math.atan2(p.y - from_point.y, p.x - from_point.x) + (random.random() - 0.5) * smoothness

    result = TPoint()
    result.x = round(p.x + math.cos(t) * skewed_rand(dist * force, 0, dist))
    result.y = round(p.y + math.sin(t) * skewed_rand(dist * force, 0, dist))

    return result


def nearest_edge_to(p, rect):
    best = TPoint()
    dist = dist_to_line_ex(p, rect.Top, rect.Left, best)
    x = TPoint()

    temp_dist = dist_to_line_ex(p, rect.Left, rect.Btm, x)
    if temp_dist < dist:
        best.x = x.x
        best.y = x.y
        dist = temp_dist

    temp_dist = dist_to_line_ex(p, rect.Btm, rect.Right, x)
    if temp_dist < dist:
        best.x = x.x
        best.y = x.y
        dist = temp_dist

    temp_dist = dist_to_line_ex(p, rect.Right, rect.Top, x)
    if temp_dist < dist:
        best.x = x.x
        best.y = x.y
        dist = temp_dist

    return best


def dice(chance_percent):
    return random.random() < chance_percent / 100


def wait(min_val, max_val, weight='wdMean'):
    if weight == 'wdLeft':
        time.sleep(round(truncated_gauss(min_val, max_val)))
    elif weight == 'wdMean':
        time.sleep(round(normal_range_float(min_val, max_val)))
    elif weight == 'wdRight':
        time.sleep(round(truncated_gauss(max_val, min_val)))
