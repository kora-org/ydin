pub fn min(a: usize, b: usize) usize {
    return if (a < b) a else b;
}

pub fn max(a: usize, b: usize) usize {
    return if (a > b) a else b;
}

pub fn divRoundup(a: usize, b: usize) usize {
    return (a + (b - 1)) / b;
}

pub fn alignUp(a: usize, b: usize) usize {
    return divRoundup(a, b) * b;
}

pub fn alignDown(a: usize, b: usize) usize {
    return (a / b) * b;
}
