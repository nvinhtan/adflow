   !        Generated by TAPENADE     (INRIA, Tropics team)
   !  Tapenade 3.6 (r4159) - 21 Sep 2011 10:11
   !
   !  Differentiation of dim in forward (tangent) mode:
   !   variations   of useful results: dim
   !   with respect to varying inputs: x y
   FUNCTION DIM_D(x, xd, y, yd, dim)
   USE PRECISION
   IMPLICIT NONE
   REAL(kind=realtype) :: x, y, z
   REAL(kind=realtype) :: xd, yd
   REAL(kind=realtype) :: dim
   REAL(kind=realtype) :: dim_d
   dim_d = xd - yd
   dim = x - y
   IF (dim .LT. 0.0) THEN
   dim = 0.0
   dim_d = 0.0_8
   END IF
   END FUNCTION DIM_D
