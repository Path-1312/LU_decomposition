import numpy as np

N = 4

A = np.random.randint(1, 10, size=(N, N)).astype(float)
for i in range(N):
    A[i, i] += np.sum(np.abs(A[i, :])) + 5

L = np.eye(N)
U = np.zeros((N, N))

for k in range(N):
    for j in range(k, N):
        U[k, j] = A[k, j] - np.dot(L[k, :k], U[:k, j])
    for i in range(k + 1, N):
        L[i, k] = (A[i, k] - np.dot(L[i, :k], U[:k, k])) / U[k, k]

LU_inplace = U.copy()
for i in range(N):
    for j in range(i):
        LU_inplace[i, j] = L[i, j]


def to_q16_16_hex(val):
    int_val = int(round(val * (1 << 16))) & 0xFFFFFFFF
    return f"{int_val:08X}"

with open("matrix_in.txt", "w") as f_in, open("golden_lu.txt", "w") as f_out:
    for i in range(N):
        for j in range(N):
            f_in.write(to_q16_16_hex(A[i, j]) + "\n")
            f_out.write(to_q16_16_hex(LU_inplace[i, j]) + "\n")

print("Generated matrix_in.txt and golden_lu.txt successfully.")