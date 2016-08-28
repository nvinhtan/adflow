!        generated by tapenade     (inria, tropics team)
!  tapenade 3.10 (r5363) -  9 sep 2014 09:53
!
module residuals_fast_b
  implicit none
! ----------------------------------------------------------------------
!                                                                      |
!                    no tapenade routine below this line               |
!                                                                      |
! ----------------------------------------------------------------------

contains
  subroutine residual_block()
!
!       residual computes the residual of the mean flow equations on   
!       the current mg level.                                          
!
    use blockpointers
    use cgnsgrid
    use flowvarrefstate
    use inputiteration
    use inputdiscretization
    use inputtimespectral
! added by hdn
    use inputunsteady
    use iteration
    use inputadjoint
    use flowutils_fast_b, only : computespeedofsoundsquared, &
&   allnodalgradients
    use fluxes_fast_b
    use aleutils_fast_b, only : interplevelale_block, recoverlevelale_block
    implicit none
!
!      local variables.
!
    integer(kind=inttype) :: discr
    integer(kind=inttype) :: i, j, k, l
! for loops of ale
    integer(kind=inttype) :: iale, jale, kale, lale, male
    real(kind=realtype), parameter :: k1=1.05_realtype
! random given number
    real(kind=realtype), parameter :: k2=0.6_realtype
! mach number preconditioner activation
    real(kind=realtype), parameter :: m0=0.2_realtype
    real(kind=realtype), parameter :: alpha=0_realtype
    real(kind=realtype), parameter :: delta=0_realtype
!real(kind=realtype), parameter :: hinf = 2_realtype ! test phase 
! test phase
    real(kind=realtype), parameter :: cpres=4.18_realtype
    real(kind=realtype), parameter :: temp=297.15_realtype
!
!     local variables
!
    real(kind=realtype) :: k3, h, velxrho, velyrho, velzrho, sos, hinf
    real(kind=realtype) :: resm, a11, a12, a13, a14, a15, a21, a22, a23&
&   , a24, a25, a31, a32, a33, a34, a35
    real(kind=realtype) :: a41, a42, a43, a44, a45, a51, a52, a53, a54, &
&   a55, b11, b12, b13, b14, b15
    real(kind=realtype) :: b21, b22, b23, b24, b25, b31, b32, b33, b34, &
&   b35
    real(kind=realtype) :: b41, b42, b43, b44, b45, b51, b52, b53, b54, &
&   b55
    real(kind=realtype) :: rhohdash, betamr2
    real(kind=realtype) :: g, q
    real(kind=realtype) :: b1, b2, b3, b4, b5
    real(kind=realtype) :: dwo(nwf)
    logical :: finegrid
    intrinsic abs
    intrinsic sqrt
    intrinsic max
    intrinsic min
    intrinsic real
    real(kind=realtype) :: x3
    real(kind=realtype) :: x2
    real(kind=realtype) :: x1
    real(kind=realtype) :: abs0
    real(kind=realtype) :: max2
    real(kind=realtype) :: max1
! set the value of rfil, which controls the fraction of the old
! dissipation residual to be used. this is only for the runge-kutta
! schemes; for other smoothers rfil is simply set to 1.0.
! note the index rkstage+1 for cdisrk. the reason is that the
! residual computation is performed before rkstage is incremented.
    if (smoother .eq. rungekutta) then
      rfil = cdisrk(rkstage+1)
    else
      rfil = one
    end if
! set the value of the discretization, depending on the grid level,
! and the logical finegrid, which indicates whether or not this
! is the finest grid level of the current mg cycle.
    discr = spacediscrcoarse
    if (currentlevel .eq. 1) discr = spacediscr
    finegrid = .false.
    if (currentlevel .eq. groundlevel) finegrid = .true.
! ===========================================================
!
! assuming ale has nothing to do with mg
! the geometric data will be interpolated if in md mode
!
! ===========================================================
! ===========================================================
!
! the fluxes are calculated as usual
!
! ===========================================================
    call inviscidcentralflux()
    select case  (discr) 
    case (dissscalar) 
! standard scalar dissipation scheme.
      if (finegrid) then
        if (.not.lumpeddiss) then
          call invisciddissfluxscalar()
        else
          call invisciddissfluxscalarapprox()
        end if
      end if
    case (dissmatrix) 
!===========================================================
! matrix dissipation scheme.
      if (finegrid) then
        if (.not.lumpeddiss) then
          call invisciddissfluxmatrix()
        else
          call invisciddissfluxmatrixapprox()
        end if
      end if
    case (upwind) 
!===========================================================
! dissipation via an upwind scheme.
      call inviscidupwindflux(finegrid)
    end select
!-------------------------------------------------------
! lastly, recover the old s[i,j,k], sface[i,j,k]
! this shall be done before difussive and source terms
! are computed.
!-------------------------------------------------------
    if (viscous) then
      if (rfil .ge. 0.) then
        abs0 = rfil
      else
        abs0 = -rfil
      end if
! only compute viscous fluxes if rfil > 0
      if (abs0 .gt. thresholdreal) then
! not lumpeddiss means it isn't the pc...call the vicousflux
        if (.not.lumpeddiss) then
          call computespeedofsoundsquared()
          call allnodalgradients()
          call viscousflux()
        else
! this is a pc calc...only include viscous fluxes if viscpc
! is used
          call computespeedofsoundsquared()
          if (viscpc) then
            call allnodalgradients()
            call viscousflux()
          else
            call viscousfluxapprox()
          end if
        end if
      end if
    end if
!===========================================================
! add the dissipative and possibly viscous fluxes to the
! euler fluxes. loop over the owned cells and add fw to dw.
! also multiply by iblank so that no updates occur in holes
    if (lowspeedpreconditioner) then
      do k=2,kl
        do j=2,jl
          do i=2,il
!    compute speed of sound
            sos = sqrt(gamma(i, j, k)*p(i, j, k)/w(i, j, k, irho))
! coompute velocities without rho from state vector
            velxrho = w(i, j, k, ivx)
            velyrho = w(i, j, k, ivy)
            velzrho = w(i, j, k, ivz)
            q = velxrho**2 + velyrho**2 + velzrho**2
            resm = sqrt(q)/sos
!
!    compute k3
            k3 = k1*(1+(1-k1*m0**2)*resm**2/(k1*m0**4))
            if (k3*(velxrho**2+velyrho**2+velzrho**2) .lt. k2*(winf(ivx)&
&               **2+winf(ivy)**2+winf(ivz)**2)) then
              x1 = k2*(winf(ivx)**2+winf(ivy)**2+winf(ivz)**2)
            else
              x1 = k3*(velxrho**2+velyrho**2+velzrho**2)
            end if
            if (x1 .gt. sos**2) then
              betamr2 = sos**2
            else
              betamr2 = x1
            end if
            a11 = betamr2*(1/sos**4)
            a12 = zero
            a13 = zero
            a14 = zero
            a15 = (-betamr2)/sos**4
            a21 = one*velxrho/sos**2
            a22 = one*w(i, j, k, irho)
            a23 = zero
            a24 = zero
            a25 = one*(-velxrho)/sos**2
            a31 = one*velyrho/sos**2
            a32 = zero
            a33 = one*w(i, j, k, irho)
            a34 = zero
            a35 = one*(-velyrho)/sos**2
            a41 = one*velzrho/sos**2
            a42 = zero
            a43 = zero
            a44 = one*w(i, j, k, irho)
            a45 = zero + one*(-velzrho)/sos**2
            a51 = one*(1/(gamma(i, j, k)-1)+resm**2/2)
            a52 = one*w(i, j, k, irho)*velxrho
            a53 = one*w(i, j, k, irho)*velyrho
            a54 = one*w(i, j, k, irho)*velzrho
            a55 = one*((-(resm**2))/2)
            b11 = a11*(gamma(i, j, k)-1)*q/2 + a12*(-velxrho)/w(i, j, k&
&             , irho) + a13*(-velyrho)/w(i, j, k, irho) + a14*(-velzrho)&
&             /w(i, j, k, irho) + a15*((gamma(i, j, k)-1)*q/2-sos**2)
            b12 = a11*(1-gamma(i, j, k))*velxrho + a12*1/w(i, j, k, irho&
&             ) + a15*(1-gamma(i, j, k))*velxrho
            b13 = a11*(1-gamma(i, j, k))*velyrho + a13/w(i, j, k, irho) &
&             + a15*(1-gamma(i, j, k))*velyrho
            b14 = a11*(1-gamma(i, j, k))*velzrho + a14/w(i, j, k, irho) &
&             + a15*(1-gamma(i, j, k))*velzrho
            b15 = a11*(gamma(i, j, k)-1) + a15*(gamma(i, j, k)-1)
            b21 = a21*(gamma(i, j, k)-1)*q/2 + a22*(-velxrho)/w(i, j, k&
&             , irho) + a23*(-velyrho)/w(i, j, k, irho) + a24*(-velzrho)&
&             /w(i, j, k, irho) + a25*((gamma(i, j, k)-1)*q/2-sos**2)
            b22 = a21*(1-gamma(i, j, k))*velxrho + a22/w(i, j, k, irho) &
&             + a25*(1-gamma(i, j, k))*velxrho
            b23 = a21*(1-gamma(i, j, k))*velyrho + a23*1/w(i, j, k, irho&
&             ) + a25*(1-gamma(i, j, k))*velyrho
            b24 = a21*(1-gamma(i, j, k))*velzrho + a24*1/w(i, j, k, irho&
&             ) + a25*(1-gamma(i, j, k))*velzrho
            b25 = a21*(gamma(i, j, k)-1) + a25*(gamma(i, j, k)-1)
            b31 = a31*(gamma(i, j, k)-1)*q/2 + a32*(-velxrho)/w(i, j, k&
&             , irho) + a33*(-velyrho)/w(i, j, k, irho) + a34*(-velzrho)&
&             /w(i, j, k, irho) + a35*((gamma(i, j, k)-1)*q/2-sos**2)
            b32 = a31*(1-gamma(i, j, k))*velxrho + a32/w(i, j, k, irho) &
&             + a35*(1-gamma(i, j, k))*velxrho
            b33 = a31*(1-gamma(i, j, k))*velyrho + a33*1/w(i, j, k, irho&
&             ) + a35*(1-gamma(i, j, k))*velyrho
            b34 = a31*(1-gamma(i, j, k))*velzrho + a34*1/w(i, j, k, irho&
&             ) + a35*(1-gamma(i, j, k))*velzrho
            b35 = a31*(gamma(i, j, k)-1) + a35*(gamma(i, j, k)-1)
            b41 = a41*(gamma(i, j, k)-1)*q/2 + a42*(-velxrho)/w(i, j, k&
&             , irho) + a43*(-velyrho)/w(i, j, k, irho) + a44*(-velzrho)&
&             /w(i, j, k, irho) + a45*((gamma(i, j, k)-1)*q/2-sos**2)
            b42 = a41*(1-gamma(i, j, k))*velxrho + a42/w(i, j, k, irho) &
&             + a45*(1-gamma(i, j, k))*velxrho
            b43 = a41*(1-gamma(i, j, k))*velyrho + a43*1/w(i, j, k, irho&
&             ) + a45*(1-gamma(i, j, k))*velyrho
            b44 = a41*(1-gamma(i, j, k))*velzrho + a44*1/w(i, j, k, irho&
&             ) + a45*(1-gamma(i, j, k))*velzrho
            b45 = a41*(gamma(i, j, k)-1) + a45*(gamma(i, j, k)-1)
            b51 = a51*(gamma(i, j, k)-1)*q/2 + a52*(-velxrho)/w(i, j, k&
&             , irho) + a53*(-velyrho)/w(i, j, k, irho) + a54*(-velzrho)&
&             /w(i, j, k, irho) + a55*((gamma(i, j, k)-1)*q/2-sos**2)
            b52 = a51*(1-gamma(i, j, k))*velxrho + a52/w(i, j, k, irho) &
&             + a55*(1-gamma(i, j, k))*velxrho
            b53 = a51*(1-gamma(i, j, k))*velyrho + a53*1/w(i, j, k, irho&
&             ) + a55*(1-gamma(i, j, k))*velyrho
            b54 = a51*(1-gamma(i, j, k))*velzrho + a54*1/w(i, j, k, irho&
&             ) + a55*(1-gamma(i, j, k))*velzrho
            b55 = a51*(gamma(i, j, k)-1) + a55*(gamma(i, j, k)-1)
! dwo is the orginal redisual
            do l=1,nwf
              x2 = real(iblank(i, j, k), realtype)
              if (x2 .lt. zero) then
                max1 = zero
              else
                max1 = x2
              end if
              dwo(l) = (dw(i, j, k, l)+fw(i, j, k, l))*max1
            end do
            dw(i, j, k, 1) = b11*dwo(1) + b12*dwo(2) + b13*dwo(3) + b14*&
&             dwo(4) + b15*dwo(5)
            dw(i, j, k, 2) = b21*dwo(1) + b22*dwo(2) + b23*dwo(3) + b24*&
&             dwo(4) + b25*dwo(5)
            dw(i, j, k, 3) = b31*dwo(1) + b32*dwo(2) + b33*dwo(3) + b34*&
&             dwo(4) + b35*dwo(5)
            dw(i, j, k, 4) = b41*dwo(1) + b42*dwo(2) + b43*dwo(3) + b44*&
&             dwo(4) + b45*dwo(5)
            dw(i, j, k, 5) = b51*dwo(1) + b52*dwo(2) + b53*dwo(3) + b54*&
&             dwo(4) + b55*dwo(5)
          end do
        end do
      end do
    else
      do l=1,nwf
        do k=2,kl
          do j=2,jl
            do i=2,il
              x3 = real(iblank(i, j, k), realtype)
              if (x3 .lt. zero) then
                max2 = zero
              else
                max2 = x3
              end if
              dw(i, j, k, l) = (dw(i, j, k, l)+fw(i, j, k, l))*max2
            end do
          end do
        end do
      end do
    end if
  end subroutine residual_block
end module residuals_fast_b
