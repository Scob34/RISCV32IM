.global _start

_start:
    nop
_init:
    nop

main:
    li x1, 2
    li x2, 2
    li x3, -1
    li x4, 0
    li x5, 0
    li x8, 0
    li x9, 0

######### BRANCH TAKEN #########

    beq x1,x2,label_taken_success
    li x8, 1 # burası atlanmalı
    j test_not_taken

label_taken_success:

    li x9,1

test_not_taken:

####### BRANCH NOT TAKEN ########

    beq x2,x3,label_not_taken_fail # aşağıdaki kod bloğu atlanmamalı, çünkü x2 ve x3 eşit değil
    li x4, 1

    j test_end

label_not_taken_fail:
    li x5, 1

test_end:
    j test_end
