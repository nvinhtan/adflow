!        generated by tapenade     (inria, tropics team)
!  tapenade 3.10 (r5363) -  9 sep 2014 09:53
!
!  differentiation of volume_block in reverse (adjoint) mode (with options i4 dr8 r8 noisize):
!   gradient     of useful results: *x *vol
!   with respect to varying inputs: *x
!   plus diff mem management of: x:in vol:in
subroutine volume_block_b()
! this is copy of metric.f90. it was necessary to copy this file
! since there is debugging stuff in the original that is not
! necessary for ad.
  use blockpointers
  use cgnsgrid
  use communication
  use inputtimespectral
  implicit none
!
!      local parameter.
!
  real(kind=realtype), parameter :: thresvolume=1.e-2_realtype
  real(kind=realtype), parameter :: halocellratio=1e-10_realtype
!
!      local variables.
!
  integer(kind=inttype) :: i, j, k, n, m, l, ii
  integer(kind=inttype) :: mm
  real(kind=realtype) :: fact, mult
  real(kind=realtype) :: xp, yp, zp, vp1, vp2, vp3, vp4, vp5, vp6
  real(kind=realtype) :: xpd, ypd, zpd, vp1d, vp2d, vp3d, vp4d, vp5d, &
& vp6d
  real(kind=realtype) :: xxp, yyp, zzp
  real(kind=realtype), dimension(3) :: v1, v2
  intrinsic abs
  real(kind=realtype) :: tmp
  real(kind=realtype) :: tmp0
  real(kind=realtype) :: tmp1
  integer :: branch
  real(kind=realtype) :: tmpd
  real(kind=realtype) :: tempd
  real(kind=realtype) :: tempd2
  real(kind=realtype) :: tempd1
  real(kind=realtype) :: tempd0
  real(kind=realtype) :: tmpd1
  real(kind=realtype) :: tmpd0
!
!      ******************************************************************
!      *                                                                *
!      * begin execution                                                *
!      *                                                                *
!      ******************************************************************
!
! compute the volumes. the hexahedron is split into 6 pyramids
! whose volumes are computed. the volume is positive for a
! right handed block.
! initialize the volumes to zero. the reasons is that the second
! level halo's must be initialized to zero and for convenience
! all the volumes are set to zero.
  vol = zero
  do k=1,ke
    call pushinteger4(n)
    n = k - 1
    do j=1,je
      call pushinteger4(m)
      m = j - 1
      do i=1,ie
        l = i - 1
! compute the coordinates of the center of gravity.
        call pushreal8(xp)
        xp = eighth*(x(i, j, k, 1)+x(i, m, k, 1)+x(i, m, n, 1)+x(i, j, n&
&         , 1)+x(l, j, k, 1)+x(l, m, k, 1)+x(l, m, n, 1)+x(l, j, n, 1))
        call pushreal8(yp)
        yp = eighth*(x(i, j, k, 2)+x(i, m, k, 2)+x(i, m, n, 2)+x(i, j, n&
&         , 2)+x(l, j, k, 2)+x(l, m, k, 2)+x(l, m, n, 2)+x(l, j, n, 2))
        call pushreal8(zp)
        zp = eighth*(x(i, j, k, 3)+x(i, m, k, 3)+x(i, m, n, 3)+x(i, j, n&
&         , 3)+x(l, j, k, 3)+x(l, m, k, 3)+x(l, m, n, 3)+x(l, j, n, 3))
! compute the volumes of the 6 sub pyramids. the
! arguments of volpym must be such that for a (regular)
! right handed hexahedron all volumes are positive.
        call volpym(x(i, j, k, 1), x(i, j, k, 2), x(i, j, k, 3), x(i, j&
&             , n, 1), x(i, j, n, 2), x(i, j, n, 3), x(i, m, n, 1), x(i&
&             , m, n, 2), x(i, m, n, 3), x(i, m, k, 1), x(i, m, k, 2), x&
&             (i, m, k, 3), vp1)
        call volpym(x(l, j, k, 1), x(l, j, k, 2), x(l, j, k, 3), x(l, m&
&             , k, 1), x(l, m, k, 2), x(l, m, k, 3), x(l, m, n, 1), x(l&
&             , m, n, 2), x(l, m, n, 3), x(l, j, n, 1), x(l, j, n, 2), x&
&             (l, j, n, 3), vp2)
        call volpym(x(i, j, k, 1), x(i, j, k, 2), x(i, j, k, 3), x(l, j&
&             , k, 1), x(l, j, k, 2), x(l, j, k, 3), x(l, j, n, 1), x(l&
&             , j, n, 2), x(l, j, n, 3), x(i, j, n, 1), x(i, j, n, 2), x&
&             (i, j, n, 3), vp3)
        call volpym(x(i, m, k, 1), x(i, m, k, 2), x(i, m, k, 3), x(i, m&
&             , n, 1), x(i, m, n, 2), x(i, m, n, 3), x(l, m, n, 1), x(l&
&             , m, n, 2), x(l, m, n, 3), x(l, m, k, 1), x(l, m, k, 2), x&
&             (l, m, k, 3), vp4)
        call volpym(x(i, j, k, 1), x(i, j, k, 2), x(i, j, k, 3), x(i, m&
&             , k, 1), x(i, m, k, 2), x(i, m, k, 3), x(l, m, k, 1), x(l&
&             , m, k, 2), x(l, m, k, 3), x(l, j, k, 1), x(l, j, k, 2), x&
&             (l, j, k, 3), vp5)
        call volpym(x(i, j, n, 1), x(i, j, n, 2), x(i, j, n, 3), x(l, j&
&             , n, 1), x(l, j, n, 2), x(l, j, n, 3), x(l, m, n, 1), x(l&
&             , m, n, 2), x(l, m, n, 3), x(i, m, n, 1), x(i, m, n, 2), x&
&             (i, m, n, 3), vp6)
! set the volume to 1/6 of the sum of the volumes of the
! pyramid. remember that volpym computes 6 times the
! volume.
        vol(i, j, k) = sixth*(vp1+vp2+vp3+vp4+vp5+vp6)
        if (vol(i, j, k) .ge. 0.) then
          call pushcontrol1b(0)
          vol(i, j, k) = vol(i, j, k)
        else
          vol(i, j, k) = -vol(i, j, k)
          call pushcontrol1b(1)
        end if
      end do
    end do
  end do
! some additional safety stuff for halo volumes.
  do k=2,kl
    do j=2,jl
      if (vol(1, j, k)/vol(2, j, k) .lt. halocellratio) then
        vol(1, j, k) = vol(2, j, k)
        call pushcontrol1b(0)
      else
        call pushcontrol1b(1)
      end if
      if (vol(ie, j, k)/vol(il, j, k) .lt. halocellratio) then
        tmp = vol(il, j, k)
        vol(ie, j, k) = tmp
        call pushcontrol1b(1)
      else
        call pushcontrol1b(0)
      end if
    end do
  end do
  do k=2,kl
    do i=1,ie
      if (vol(i, 1, k)/vol(i, 2, k) .lt. halocellratio) then
        vol(i, 1, k) = vol(i, 2, k)
        call pushcontrol1b(0)
      else
        call pushcontrol1b(1)
      end if
      if (vol(i, je, k)/vol(i, jl, k) .lt. halocellratio) then
        tmp0 = vol(i, jl, k)
        vol(i, je, k) = tmp0
        call pushcontrol1b(1)
      else
        call pushcontrol1b(0)
      end if
    end do
  end do
  do j=1,je
    do i=1,ie
      if (vol(i, j, 1)/vol(i, j, 2) .lt. halocellratio) then
        vol(i, j, 1) = vol(i, j, 2)
        call pushcontrol1b(0)
      else
        call pushcontrol1b(1)
      end if
      if (vol(i, j, ke)/vol(i, j, kl) .lt. halocellratio) then
        tmp1 = vol(i, j, kl)
        vol(i, j, ke) = tmp1
        call pushcontrol1b(1)
      else
        call pushcontrol1b(0)
      end if
    end do
  end do
  do j=je,1,-1
    do i=ie,1,-1
      call popcontrol1b(branch)
      if (branch .ne. 0) then
        tmpd1 = vold(i, j, ke)
        vold(i, j, ke) = 0.0_8
        vold(i, j, kl) = vold(i, j, kl) + tmpd1
      end if
      call popcontrol1b(branch)
      if (branch .eq. 0) then
        vold(i, j, 2) = vold(i, j, 2) + vold(i, j, 1)
        vold(i, j, 1) = 0.0_8
      end if
    end do
  end do
  do k=kl,2,-1
    do i=ie,1,-1
      call popcontrol1b(branch)
      if (branch .ne. 0) then
        tmpd0 = vold(i, je, k)
        vold(i, je, k) = 0.0_8
        vold(i, jl, k) = vold(i, jl, k) + tmpd0
      end if
      call popcontrol1b(branch)
      if (branch .eq. 0) then
        vold(i, 2, k) = vold(i, 2, k) + vold(i, 1, k)
        vold(i, 1, k) = 0.0_8
      end if
    end do
  end do
  do k=kl,2,-1
    do j=jl,2,-1
      call popcontrol1b(branch)
      if (branch .ne. 0) then
        tmpd = vold(ie, j, k)
        vold(ie, j, k) = 0.0_8
        vold(il, j, k) = vold(il, j, k) + tmpd
      end if
      call popcontrol1b(branch)
      if (branch .eq. 0) then
        vold(2, j, k) = vold(2, j, k) + vold(1, j, k)
        vold(1, j, k) = 0.0_8
      end if
    end do
  end do
  vp1d = 0.0_8
  vp2d = 0.0_8
  vp3d = 0.0_8
  vp4d = 0.0_8
  vp5d = 0.0_8
  vp6d = 0.0_8
  do k=ke,1,-1
    do j=je,1,-1
      do i=ie,1,-1
        call popcontrol1b(branch)
        if (branch .ne. 0) vold(i, j, k) = -vold(i, j, k)
        tempd = sixth*vold(i, j, k)
        vp1d = vp1d + tempd
        vp2d = vp2d + tempd
        vp3d = vp3d + tempd
        vp4d = vp4d + tempd
        vp5d = vp5d + tempd
        vp6d = vp6d + tempd
        vold(i, j, k) = 0.0_8
        l = i - 1
        zpd = 0.0_8
        ypd = 0.0_8
        xpd = 0.0_8
        call volpym_b(x(i, j, n, 1), xd(i, j, n, 1), x(i, j, n, 2), xd(i&
&               , j, n, 2), x(i, j, n, 3), xd(i, j, n, 3), x(l, j, n, 1)&
&               , xd(l, j, n, 1), x(l, j, n, 2), xd(l, j, n, 2), x(l, j&
&               , n, 3), xd(l, j, n, 3), x(l, m, n, 1), xd(l, m, n, 1), &
&               x(l, m, n, 2), xd(l, m, n, 2), x(l, m, n, 3), xd(l, m, n&
&               , 3), x(i, m, n, 1), xd(i, m, n, 1), x(i, m, n, 2), xd(i&
&               , m, n, 2), x(i, m, n, 3), xd(i, m, n, 3), vp6, vp6d)
        vp6d = 0.0_8
        call volpym_b(x(i, j, k, 1), xd(i, j, k, 1), x(i, j, k, 2), xd(i&
&               , j, k, 2), x(i, j, k, 3), xd(i, j, k, 3), x(i, m, k, 1)&
&               , xd(i, m, k, 1), x(i, m, k, 2), xd(i, m, k, 2), x(i, m&
&               , k, 3), xd(i, m, k, 3), x(l, m, k, 1), xd(l, m, k, 1), &
&               x(l, m, k, 2), xd(l, m, k, 2), x(l, m, k, 3), xd(l, m, k&
&               , 3), x(l, j, k, 1), xd(l, j, k, 1), x(l, j, k, 2), xd(l&
&               , j, k, 2), x(l, j, k, 3), xd(l, j, k, 3), vp5, vp5d)
        vp5d = 0.0_8
        call volpym_b(x(i, m, k, 1), xd(i, m, k, 1), x(i, m, k, 2), xd(i&
&               , m, k, 2), x(i, m, k, 3), xd(i, m, k, 3), x(i, m, n, 1)&
&               , xd(i, m, n, 1), x(i, m, n, 2), xd(i, m, n, 2), x(i, m&
&               , n, 3), xd(i, m, n, 3), x(l, m, n, 1), xd(l, m, n, 1), &
&               x(l, m, n, 2), xd(l, m, n, 2), x(l, m, n, 3), xd(l, m, n&
&               , 3), x(l, m, k, 1), xd(l, m, k, 1), x(l, m, k, 2), xd(l&
&               , m, k, 2), x(l, m, k, 3), xd(l, m, k, 3), vp4, vp4d)
        vp4d = 0.0_8
        call volpym_b(x(i, j, k, 1), xd(i, j, k, 1), x(i, j, k, 2), xd(i&
&               , j, k, 2), x(i, j, k, 3), xd(i, j, k, 3), x(l, j, k, 1)&
&               , xd(l, j, k, 1), x(l, j, k, 2), xd(l, j, k, 2), x(l, j&
&               , k, 3), xd(l, j, k, 3), x(l, j, n, 1), xd(l, j, n, 1), &
&               x(l, j, n, 2), xd(l, j, n, 2), x(l, j, n, 3), xd(l, j, n&
&               , 3), x(i, j, n, 1), xd(i, j, n, 1), x(i, j, n, 2), xd(i&
&               , j, n, 2), x(i, j, n, 3), xd(i, j, n, 3), vp3, vp3d)
        vp3d = 0.0_8
        call volpym_b(x(l, j, k, 1), xd(l, j, k, 1), x(l, j, k, 2), xd(l&
&               , j, k, 2), x(l, j, k, 3), xd(l, j, k, 3), x(l, m, k, 1)&
&               , xd(l, m, k, 1), x(l, m, k, 2), xd(l, m, k, 2), x(l, m&
&               , k, 3), xd(l, m, k, 3), x(l, m, n, 1), xd(l, m, n, 1), &
&               x(l, m, n, 2), xd(l, m, n, 2), x(l, m, n, 3), xd(l, m, n&
&               , 3), x(l, j, n, 1), xd(l, j, n, 1), x(l, j, n, 2), xd(l&
&               , j, n, 2), x(l, j, n, 3), xd(l, j, n, 3), vp2, vp2d)
        vp2d = 0.0_8
        call volpym_b(x(i, j, k, 1), xd(i, j, k, 1), x(i, j, k, 2), xd(i&
&               , j, k, 2), x(i, j, k, 3), xd(i, j, k, 3), x(i, j, n, 1)&
&               , xd(i, j, n, 1), x(i, j, n, 2), xd(i, j, n, 2), x(i, j&
&               , n, 3), xd(i, j, n, 3), x(i, m, n, 1), xd(i, m, n, 1), &
&               x(i, m, n, 2), xd(i, m, n, 2), x(i, m, n, 3), xd(i, m, n&
&               , 3), x(i, m, k, 1), xd(i, m, k, 1), x(i, m, k, 2), xd(i&
&               , m, k, 2), x(i, m, k, 3), xd(i, m, k, 3), vp1, vp1d)
        vp1d = 0.0_8
        call popreal8(zp)
        tempd0 = eighth*zpd
        xd(i, j, k, 3) = xd(i, j, k, 3) + tempd0
        xd(i, m, k, 3) = xd(i, m, k, 3) + tempd0
        xd(i, m, n, 3) = xd(i, m, n, 3) + tempd0
        xd(i, j, n, 3) = xd(i, j, n, 3) + tempd0
        xd(l, j, k, 3) = xd(l, j, k, 3) + tempd0
        xd(l, m, k, 3) = xd(l, m, k, 3) + tempd0
        xd(l, m, n, 3) = xd(l, m, n, 3) + tempd0
        xd(l, j, n, 3) = xd(l, j, n, 3) + tempd0
        call popreal8(yp)
        tempd1 = eighth*ypd
        xd(i, j, k, 2) = xd(i, j, k, 2) + tempd1
        xd(i, m, k, 2) = xd(i, m, k, 2) + tempd1
        xd(i, m, n, 2) = xd(i, m, n, 2) + tempd1
        xd(i, j, n, 2) = xd(i, j, n, 2) + tempd1
        xd(l, j, k, 2) = xd(l, j, k, 2) + tempd1
        xd(l, m, k, 2) = xd(l, m, k, 2) + tempd1
        xd(l, m, n, 2) = xd(l, m, n, 2) + tempd1
        xd(l, j, n, 2) = xd(l, j, n, 2) + tempd1
        call popreal8(xp)
        tempd2 = eighth*xpd
        xd(i, j, k, 1) = xd(i, j, k, 1) + tempd2
        xd(i, m, k, 1) = xd(i, m, k, 1) + tempd2
        xd(i, m, n, 1) = xd(i, m, n, 1) + tempd2
        xd(i, j, n, 1) = xd(i, j, n, 1) + tempd2
        xd(l, j, k, 1) = xd(l, j, k, 1) + tempd2
        xd(l, m, k, 1) = xd(l, m, k, 1) + tempd2
        xd(l, m, n, 1) = xd(l, m, n, 1) + tempd2
        xd(l, j, n, 1) = xd(l, j, n, 1) + tempd2
      end do
      call popinteger4(m)
    end do
    call popinteger4(n)
  end do

contains
!  differentiation of volpym in reverse (adjoint) mode (with options i4 dr8 r8 noisize):
!   gradient     of useful results: xp yp zp xa xb xc xd ya yb
!                yc yd za zb zc zd volume
!   with respect to varying inputs: xp yp zp xa xb xc xd ya yb
!                yc yd za zb zc zd
  subroutine volpym_b(xa, xad, ya, yad, za, zad, xb, xbd, yb, ybd, zb, &
&   zbd, xc, xcd, yc, ycd, zc, zcd, xd, xdd, yd, ydd, zd, zdd, volume, &
&   volumed)
!
!        ****************************************************************
!        *                                                              *
!        * volpym computes 6 times the volume of a pyramid. node p,     *
!        * whose coordinates are set in the subroutine metric itself,   *
!        * is the top node and a-b-c-d is the quadrilateral surface.    *
!        * it is assumed that the cross product vca * vdb points in     *
!        * the direction of the top node. here vca is the diagonal      *
!        * running from node c to node a and vdb the diagonal from      *
!        * node d to node b.                                            *
!        *                                                              *
!        ****************************************************************
!
    use precision
    implicit none
!
!        function type.
!
    real(kind=realtype) :: volume
    real(kind=realtype) :: volumed
!
!        function arguments.
!
    real(kind=realtype), intent(in) :: xa, ya, za, xb, yb, zb
    real(kind=realtype) :: xad, yad, zad, xbd, ybd, zbd
    real(kind=realtype), intent(in) :: xc, yc, zc, xd, yd, zd
    real(kind=realtype) :: xcd, ycd, zcd, xdd, ydd, zdd
!
!        ****************************************************************
!        *                                                              *
!        * begin execution                                              *
!        *                                                              *
!        ****************************************************************
!
    real(kind=realtype) :: tempd
    real(kind=realtype) :: tempd7
    real(kind=realtype) :: tempd6
    real(kind=realtype) :: tempd5
    real(kind=realtype) :: tempd4
    real(kind=realtype) :: tempd3
    real(kind=realtype) :: tempd2
    real(kind=realtype) :: tempd1
    real(kind=realtype) :: tempd0
    tempd = ((ya-yc)*(zb-zd)-(za-zc)*(yb-yd))*volumed
    tempd0 = -(fourth*tempd)
    tempd1 = (xp-fourth*(xa+xb+xc+xd))*volumed
    tempd2 = ((za-zc)*(xb-xd)-(xa-xc)*(zb-zd))*volumed
    tempd3 = -(fourth*tempd2)
    tempd4 = (yp-fourth*(ya+yb+yc+yd))*volumed
    tempd5 = ((xa-xc)*(yb-yd)-(ya-yc)*(xb-xd))*volumed
    tempd6 = -(fourth*tempd5)
    tempd7 = (zp-fourth*(za+zb+zc+zd))*volumed
    xpd = xpd + tempd
    xad = xad + (yb-yd)*tempd7 - (zb-zd)*tempd4 + tempd0
    xbd = xbd + (za-zc)*tempd4 - (ya-yc)*tempd7 + tempd0
    xcd = xcd + (zb-zd)*tempd4 - (yb-yd)*tempd7 + tempd0
    xdd = xdd + (ya-yc)*tempd7 - (za-zc)*tempd4 + tempd0
    yad = yad + tempd3 - (xb-xd)*tempd7 + (zb-zd)*tempd1
    ycd = ycd + (xb-xd)*tempd7 + tempd3 - (zb-zd)*tempd1
    zbd = zbd + tempd6 - (xa-xc)*tempd4 + (ya-yc)*tempd1
    zdd = zdd + tempd6 + (xa-xc)*tempd4 - (ya-yc)*tempd1
    zad = zad + tempd6 + (xb-xd)*tempd4 - (yb-yd)*tempd1
    zcd = zcd + tempd6 - (xb-xd)*tempd4 + (yb-yd)*tempd1
    ybd = ybd + (xa-xc)*tempd7 + tempd3 - (za-zc)*tempd1
    ydd = ydd + tempd3 - (xa-xc)*tempd7 + (za-zc)*tempd1
    ypd = ypd + tempd2
    zpd = zpd + tempd5
  end subroutine volpym_b
  subroutine volpym(xa, ya, za, xb, yb, zb, xc, yc, zc, xd, yd, zd, &
&   volume)
!
!        ****************************************************************
!        *                                                              *
!        * volpym computes 6 times the volume of a pyramid. node p,     *
!        * whose coordinates are set in the subroutine metric itself,   *
!        * is the top node and a-b-c-d is the quadrilateral surface.    *
!        * it is assumed that the cross product vca * vdb points in     *
!        * the direction of the top node. here vca is the diagonal      *
!        * running from node c to node a and vdb the diagonal from      *
!        * node d to node b.                                            *
!        *                                                              *
!        ****************************************************************
!
    use precision
    implicit none
!
!        function type.
!
    real(kind=realtype) :: volume
!
!        function arguments.
!
    real(kind=realtype), intent(in) :: xa, ya, za, xb, yb, zb
    real(kind=realtype), intent(in) :: xc, yc, zc, xd, yd, zd
!
!        ****************************************************************
!        *                                                              *
!        * begin execution                                              *
!        *                                                              *
!        ****************************************************************
!
    volume = (xp-fourth*(xa+xb+xc+xd))*((ya-yc)*(zb-zd)-(za-zc)*(yb-yd))&
&     + (yp-fourth*(ya+yb+yc+yd))*((za-zc)*(xb-xd)-(xa-xc)*(zb-zd)) + (&
&     zp-fourth*(za+zb+zc+zd))*((xa-xc)*(yb-yd)-(ya-yc)*(xb-xd))
  end subroutine volpym
end subroutine volume_block_b
