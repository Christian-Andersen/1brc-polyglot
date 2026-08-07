program main
  implicit none
  integer, parameter :: cap = 65536
  character(len=64) :: city
  character(len=32) :: temp, digits
  character(len=256) :: line
  integer :: io, i, j, k, n, idx
  integer(kind=8) :: value
  integer(kind=4) :: mn(0:cap-1), mx(0:cap-1)
  integer(kind=8) :: total(0:cap-1), cnt(0:cap-1)
  integer :: used(0:cap-1), order(0:cap-1)
  character(len=64) :: names(0:cap-1)

  used = 0
  open(unit=10, file="../../data/measurements.txt", status="old", iostat=io)
  if (io /= 0) stop "cannot open measurements"

  do
    read(10, '(A)', iostat=io) line
    if (io /= 0) exit
    k = index(line, ";")
    if (k == 0) cycle
    city = line(1:k-1)
    temp = trim(line(k+1:))
    digits = ""
    j = 1
    do i = 1, len_trim(temp)
      if (temp(i:i) /= ".") then
        digits(j:j) = temp(i:i)
        j = j + 1
      end if
    end do
    read(digits, *) value

    idx = hashf(city)
    do while (used(idx) == 1 .and. names(idx) /= city)
      idx = mod(idx + 1, cap)
    end do

    if (used(idx) == 0) then
      used(idx) = 1
      names(idx) = city
      mn(idx) = int(value, 4)
      mx(idx) = int(value, 4)
      total(idx) = value
      cnt(idx) = 1
    else
      if (value < mn(idx)) mn(idx) = int(value, 4)
      if (value > mx(idx)) mx(idx) = int(value, 4)
      total(idx) = total(idx) + value
      cnt(idx) = cnt(idx) + 1
    end if
  end do
  close(10)

  n = 0
  do i = 0, cap - 1
    if (used(i) == 1) then
      order(n) = i
      n = n + 1
    end if
  end do

  do i = 1, n - 1
    k = order(i)
    j = i - 1
    do while (j >= 0 .and. names(order(j)) > names(k))
      order(j+1) = order(j)
      j = j - 1
    end do
    order(j+1) = k
  end do

  do i = 0, n - 1
    k = order(i)
    write(*, '(A, A, I0, A, I0, A, I0, A, I0)') &
      trim(names(k)), achar(9), mn(k), achar(9), mx(k), achar(9), total(k), achar(9), cnt(k)
  end do

contains

  function hashf(str) result(h)
    character(len=*), intent(in) :: str
    integer :: h, i
    h = 0
    do i = 1, len_trim(str)
      h = mod(h * 31 + ichar(str(i:i)), cap)
    end do
    h = mod(h, cap)
  end function hashf

end program main
