# RISCV-CPU

### Some Const

`ROB_SIZE` : 32

`RS_SIZE` : 16

`REG_SIZE` : 32

`LSB_SIZE` : 16

`ICache` : 256 ( direct mapping )



### FPGA time

| testpoint      | time       |
| -------------- | ---------- |
| array_test1    | 0.005651   |
| array_test2    | 0.005738   |
| basicopt1      | 0.021001   |
| bulgarian      | 2.470735   |
| expr           | 0.005690   |
| gcd            | 0.005630   |
| heart          | 851.485831 |
| hanoi          | 4.855632   |
| looper         | 11.130910  |
| lvalue2        | 0.013473   |
| magic          | 0.025823   |
| manyarguments  | 0.012771   |
| multiarray     | 0.027038   |
| pi             | 3.266114   |
| qsort          | 8.825039   |
| queens         | 4.151746   |
| statement_test | 0.003293   |
| superloop      | 0.019021   |
| tak            | 0.052601   |
| testsleep      | 9.691126   |
| uartboom       | 0.763954   |



### Tricky Design

- apply combinational logic in `memCtrl`, which is expected to cut down memory access time by at least $\frac{1}{5}$

- apply `ROB_WRAP_POS_TYPE` with value $(1,$ `ROB_POS_TYPE` $)$ if valid, and `0` if invalid



### Bad Design

- branch predictor with only two bit (terrible hit rate)
- use a reg to store the number of lines in use in `ROB` , `RS` , `LSB`, this greatly increase the `Worst Negative Slack` when synthesizing with `Vivado`