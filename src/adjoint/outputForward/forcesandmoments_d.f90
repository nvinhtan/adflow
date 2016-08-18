!        generated by tapenade     (inria, tropics team)
!  tapenade 3.10 (r5363) -  9 sep 2014 09:53
!
!  differentiation of forcesandmoments in forward (tangent) mode (with options i4 dr8 r8):
!   variations   of useful results: *(*bcdata.fv) *(*bcdata.fp)
!                *(*bcdata.area) sepsensoravg cfp cfv cmp cmv cavitation
!                sepsensor
!   with respect to varying inputs: gammainf pinf pref *p *w *x
!                *si *sj *sk *(*viscsubface.tau) veldirfreestream
!                lengthref machcoef pointref *xx *pp1 *pp2 *ssi
!                *ww2
!   plus diff mem management of: viscsubface:in *viscsubface.tau:in
!                bcdata:in *bcdata.fv:in *bcdata.fp:in *bcdata.area:in
!                xx:in-out rev0:out rev1:out rev2:out rev3:out
!                pp0:out pp1:in-out pp2:in-out pp3:out rlv0:out
!                rlv1:out rlv2:out rlv3:out ss:out ssi:in-out ssj:out
!                ssk:out ww0:out ww1:in-out ww2:in-out ww3:out
!
!      ******************************************************************
!      *                                                                *
!      * file:          forcesandmoments.f90                            *
!      * author:        edwin van der weide                             *
!      * starting date: 04-01-2003                                      *
!      * last modified: 06-12-2005                                      *
!      *                                                                *
!      ******************************************************************
!
subroutine forcesandmoments_d(cfp, cfpd, cfv, cfvd, cmp, cmpd, cmv, cmvd&
& , yplusmax, sepsensor, sepsensord, sepsensoravg, sepsensoravgd, &
& cavitation, cavitationd)
!
!      ******************************************************************
!      *                                                                *
!      * forcesandmoments computes the contribution of the block        *
!      * given by the pointers in blockpointers to the force and        *
!      * moment coefficients of the geometry. a distinction is made     *
!      * between the inviscid and viscous parts. in case the maximum    *
!      * yplus value must be monitored (only possible for rans), this   *
!      * value is also computed. the separation sensor and the cavita-  *
!      * tion sensor is also computed                                   *
!      * here.                                                          *
!      ******************************************************************
!
  use blockpointers
  use bctypes
  use flowvarrefstate
  use inputphysics
  use bcroutines_d
  use costfunctions
  use surfacefamilies
  use diffsizes
!  hint: isize1ofdrfbcdata should be the size of dimension 1 of array *bcdata
  implicit none
!
!      subroutine arguments
!
  real(kind=realtype), dimension(3), intent(out) :: cfp, cfv
  real(kind=realtype), dimension(3), intent(out) :: cfpd, cfvd
  real(kind=realtype), dimension(3), intent(out) :: cmp, cmv
  real(kind=realtype), dimension(3), intent(out) :: cmpd, cmvd
  real(kind=realtype), intent(out) :: yplusmax, sepsensor
  real(kind=realtype), intent(out) :: sepsensord
  real(kind=realtype), intent(out) :: sepsensoravg(3), cavitation
  real(kind=realtype), intent(out) :: sepsensoravgd(3), cavitationd
!
!      local variables.
!
  integer(kind=inttype) :: nn, i, j, ii, bsearchintegers
  real(kind=realtype) :: pm1, fx, fy, fz, fn, sigma
  real(kind=realtype) :: pm1d, fxd, fyd, fzd
  real(kind=realtype) :: xc, yc, zc, qf(3)
  real(kind=realtype) :: xcd, ycd, zcd
  real(kind=realtype) :: fact, rho, mul, yplus, dwall
  real(kind=realtype) :: factd
  real(kind=realtype) :: scaledim, v(3), sensor, sensor1, cp, tmp, &
& plocal
  real(kind=realtype) :: scaledimd, vd(3), sensord, sensor1d, cpd, tmpd&
& , plocald
  real(kind=realtype) :: tauxx, tauyy, tauzz
  real(kind=realtype) :: tauxxd, tauyyd, tauzzd
  real(kind=realtype) :: tauxy, tauxz, tauyz
  real(kind=realtype) :: tauxyd, tauxzd, tauyzd
  real(kind=realtype), dimension(3) :: refpoint
  real(kind=realtype), dimension(3) :: refpointd
  real(kind=realtype) :: mx, my, mz, cellarea
  real(kind=realtype) :: mxd, myd, mzd, cellaread
  logical :: viscoussubface
  intrinsic shape
  intrinsic mod
  intrinsic sqrt
  intrinsic exp
  intrinsic max
  real(kind=realtype) :: arg1
  real(kind=realtype) :: arg1d
  real(kind=realtype) :: result1
  real(kind=realtype) :: result1d
  real(kind=realtype) :: arg2
  real(kind=realtype) :: result2
  integer :: ii1
!
!      ******************************************************************
!      *                                                                *
!      * begin execution                                                *
!      *                                                                *
!      ******************************************************************
!
! set the actual scaling factor such that actual forces are computed
  scaledimd = (prefd*pinf-pref*pinfd)/pinf**2
  scaledim = pref/pinf
! determine the reference point for the moment computation in
! meters.
  refpointd = 0.0_8
  refpointd(1) = lref*pointrefd(1)
  refpoint(1) = lref*pointref(1)
  refpointd(2) = lref*pointrefd(2)
  refpoint(2) = lref*pointref(2)
  refpointd(3) = lref*pointrefd(3)
  refpoint(3) = lref*pointref(3)
! initialize the force and moment coefficients to 0 as well as
! yplusmax.
  cfp(1) = zero
  cfp(2) = zero
  cfp(3) = zero
  cfv(1) = zero
  cfv(2) = zero
  cfv(3) = zero
  cmp(1) = zero
  cmp(2) = zero
  cmp(3) = zero
  cmv(1) = zero
  cmv(2) = zero
  cmv(3) = zero
  yplusmax = zero
  sepsensor = zero
  cavitation = zero
  sepsensoravg = zero
  do ii1=1,isize1ofdrfbcdata
    bcdatad(ii1)%fv = 0.0_8
  end do
  do ii1=1,isize1ofdrfbcdata
    bcdatad(ii1)%fp = 0.0_8
  end do
  do ii1=1,isize1ofdrfbcdata
    bcdatad(ii1)%area = 0.0_8
  end do
  sepsensoravgd = 0.0_8
  cfpd = 0.0_8
  cfvd = 0.0_8
  cmpd = 0.0_8
  cmvd = 0.0_8
  cavitationd = 0.0_8
  sepsensord = 0.0_8
  vd = 0.0_8
! loop over the boundary subfaces of this block.
bocos:do nn=1,nbocos
!
!        ****************************************************************
!        *                                                              *
!        * integrate the inviscid contribution over the solid walls,    *
!        * either inviscid or viscous. the integration is done with     *
!        * cp. for closed contours this is equal to the integration     *
!        * of p; for open contours this is not the case anymore.        *
!        * question is whether a force for an open contour is           *
!        * meaningful anyway.                                           *
!        *                                                              *
!        ****************************************************************
!
    if (bsearchintegers(bcdata(nn)%famid, famgroups, shape(famgroups)) &
&       .gt. 0) then
      if ((bctype(nn) .eq. eulerwall .or. bctype(nn) .eq. &
&         nswalladiabatic) .or. bctype(nn) .eq. nswallisothermal) then
! subface is a wall. check if it is a viscous wall.
        viscoussubface = .true.
        if (bctype(nn) .eq. eulerwall) viscoussubface = .false.
! set a bunch of pointers depending on the face id to make
! a generic treatment possible. the routine setbcpointers
! is not used, because quite a few other ones are needed.
        call setbcpointers_d(nn, .true.)
        select case  (bcfaceid(nn)) 
        case (imin) 
          fact = -one
        case (imax) 
          fact = one
        case (jmin) 
          fact = -one
        case (jmax) 
          fact = one
        case (kmin) 
          fact = -one
        case (kmax) 
          fact = one
        end select
! loop over the quadrilateral faces of the subface. note that
! the nodal range of bcdata must be used and not the cell
! range, because the latter may include the halo's in i and
! j-direction. the offset +1 is there, because inbeg and jnbeg
! refer to nodal ranges and not to cell ranges. the loop
! (without the ad stuff) would look like:
!
! do j=(bcdata(nn)%jnbeg+1),bcdata(nn)%jnend
!    do i=(bcdata(nn)%inbeg+1),bcdata(nn)%inend
        do ii=0,(bcdata(nn)%jnend-bcdata(nn)%jnbeg)*(bcdata(nn)%inend-&
&           bcdata(nn)%inbeg)-1
          i = mod(ii, bcdata(nn)%inend - bcdata(nn)%inbeg) + bcdata(nn)%&
&           inbeg + 1
          j = ii/(bcdata(nn)%inend-bcdata(nn)%inbeg) + bcdata(nn)%jnbeg &
&           + 1
! compute the average pressure minus 1 and the coordinates
! of the centroid of the face relative from from the
! moment reference point. due to the usage of pointers for
! the coordinates, whose original array starts at 0, an
! offset of 1 must be used. the pressure is multipled by
! fact to account for the possibility of an inward or
! outward pointing normal.
          pm1d = fact*((half*(pp2d(i, j)+pp1d(i, j))-pinfd)*scaledim+(&
&           half*(pp2(i, j)+pp1(i, j))-pinf)*scaledimd)
          pm1 = fact*(half*(pp2(i, j)+pp1(i, j))-pinf)*scaledim
          xcd = fourth*(xxd(i, j, 1)+xxd(i+1, j, 1)+xxd(i, j+1, 1)+xxd(i&
&           +1, j+1, 1)) - refpointd(1)
          xc = fourth*(xx(i, j, 1)+xx(i+1, j, 1)+xx(i, j+1, 1)+xx(i+1, j&
&           +1, 1)) - refpoint(1)
          ycd = fourth*(xxd(i, j, 2)+xxd(i+1, j, 2)+xxd(i, j+1, 2)+xxd(i&
&           +1, j+1, 2)) - refpointd(2)
          yc = fourth*(xx(i, j, 2)+xx(i+1, j, 2)+xx(i, j+1, 2)+xx(i+1, j&
&           +1, 2)) - refpoint(2)
          zcd = fourth*(xxd(i, j, 3)+xxd(i+1, j, 3)+xxd(i, j+1, 3)+xxd(i&
&           +1, j+1, 3)) - refpointd(3)
          zc = fourth*(xx(i, j, 3)+xx(i+1, j, 3)+xx(i, j+1, 3)+xx(i+1, j&
&           +1, 3)) - refpoint(3)
! compute the force components.
          fxd = pm1d*ssi(i, j, 1) + pm1*ssid(i, j, 1)
          fx = pm1*ssi(i, j, 1)
          fyd = pm1d*ssi(i, j, 2) + pm1*ssid(i, j, 2)
          fy = pm1*ssi(i, j, 2)
          fzd = pm1d*ssi(i, j, 3) + pm1*ssid(i, j, 3)
          fz = pm1*ssi(i, j, 3)
! update the inviscid force and moment coefficients.
          cfpd(1) = cfpd(1) + fxd
          cfp(1) = cfp(1) + fx
          cfpd(2) = cfpd(2) + fyd
          cfp(2) = cfp(2) + fy
          cfpd(3) = cfpd(3) + fzd
          cfp(3) = cfp(3) + fz
          mxd = ycd*fz + yc*fzd - zcd*fy - zc*fyd
          mx = yc*fz - zc*fy
          myd = zcd*fx + zc*fxd - xcd*fz - xc*fzd
          my = zc*fx - xc*fz
          mzd = xcd*fy + xc*fyd - ycd*fx - yc*fxd
          mz = xc*fy - yc*fx
          cmpd(1) = cmpd(1) + mxd
          cmp(1) = cmp(1) + mx
          cmpd(2) = cmpd(2) + myd
          cmp(2) = cmp(2) + my
          cmpd(3) = cmpd(3) + mzd
          cmp(3) = cmp(3) + mz
! save the face-based forces and area
          bcdatad(nn)%fp(i, j, 1) = fxd
          bcdata(nn)%fp(i, j, 1) = fx
          bcdatad(nn)%fp(i, j, 2) = fyd
          bcdata(nn)%fp(i, j, 2) = fy
          bcdatad(nn)%fp(i, j, 3) = fzd
          bcdata(nn)%fp(i, j, 3) = fz
          arg1d = 2*ssi(i, j, 1)*ssid(i, j, 1) + 2*ssi(i, j, 2)*ssid(i, &
&           j, 2) + 2*ssi(i, j, 3)*ssid(i, j, 3)
          arg1 = ssi(i, j, 1)**2 + ssi(i, j, 2)**2 + ssi(i, j, 3)**2
          if (arg1 .eq. 0.0_8) then
            cellaread = 0.0_8
          else
            cellaread = arg1d/(2.0*sqrt(arg1))
          end if
          cellarea = sqrt(arg1)
          bcdatad(nn)%area(i, j) = cellaread
          bcdata(nn)%area(i, j) = cellarea
! get normalized surface velocity:
          vd(1) = ww2d(i, j, ivx)
          v(1) = ww2(i, j, ivx)
          vd(2) = ww2d(i, j, ivy)
          v(2) = ww2(i, j, ivy)
          vd(3) = ww2d(i, j, ivz)
          v(3) = ww2(i, j, ivz)
          arg1d = 2*v(1)*vd(1) + 2*v(2)*vd(2) + 2*v(3)*vd(3)
          arg1 = v(1)**2 + v(2)**2 + v(3)**2
          if (arg1 .eq. 0.0_8) then
            result1d = 0.0_8
          else
            result1d = arg1d/(2.0*sqrt(arg1))
          end if
          result1 = sqrt(arg1)
          vd = (vd*(result1+1e-16)-v*result1d)/(result1+1e-16)**2
          v = v/(result1+1e-16)
! dot product with free stream
          sensord = -(vd(1)*veldirfreestream(1)+v(1)*veldirfreestreamd(1&
&           )+vd(2)*veldirfreestream(2)+v(2)*veldirfreestreamd(2)+vd(3)*&
&           veldirfreestream(3)+v(3)*veldirfreestreamd(3))
          sensor = -(v(1)*veldirfreestream(1)+v(2)*veldirfreestream(2)+v&
&           (3)*veldirfreestream(3))
!now run through a smooth heaviside function:
          arg1d = -(2*sepsensorsharpness*sensord)
          arg1 = -(2*sepsensorsharpness*(sensor-sepsensoroffset))
          sensord = -(one*arg1d*exp(arg1)/(one+exp(arg1))**2)
          sensor = one/(one+exp(arg1))
! and integrate over the area of this cell and save:
          sensord = sensord*cellarea + sensor*cellaread
          sensor = sensor*cellarea
          sepsensord = sepsensord + sensord
          sepsensor = sepsensor + sensor
! also accumulate into the sepsensoravg
          xcd = fourth*(xxd(i, j, 1)+xxd(i+1, j, 1)+xxd(i, j+1, 1)+xxd(i&
&           +1, j+1, 1))
          xc = fourth*(xx(i, j, 1)+xx(i+1, j, 1)+xx(i, j+1, 1)+xx(i+1, j&
&           +1, 1))
          ycd = fourth*(xxd(i, j, 2)+xxd(i+1, j, 2)+xxd(i, j+1, 2)+xxd(i&
&           +1, j+1, 2))
          yc = fourth*(xx(i, j, 2)+xx(i+1, j, 2)+xx(i, j+1, 2)+xx(i+1, j&
&           +1, 2))
          zcd = fourth*(xxd(i, j, 3)+xxd(i+1, j, 3)+xxd(i, j+1, 3)+xxd(i&
&           +1, j+1, 3))
          zc = fourth*(xx(i, j, 3)+xx(i+1, j, 3)+xx(i, j+1, 3)+xx(i+1, j&
&           +1, 3))
          sepsensoravgd(1) = sepsensoravgd(1) + sensord*xc + sensor*xcd
          sepsensoravg(1) = sepsensoravg(1) + sensor*xc
          sepsensoravgd(2) = sepsensoravgd(2) + sensord*yc + sensor*ycd
          sepsensoravg(2) = sepsensoravg(2) + sensor*yc
          sepsensoravgd(3) = sepsensoravgd(3) + sensord*zc + sensor*zcd
          sepsensoravg(3) = sepsensoravg(3) + sensor*zc
          plocald = pp2d(i, j)
          plocal = pp2(i, j)
          tmpd = -(two*((gammainfd*pinf+gammainf*pinfd)*machcoef**2+&
&           gammainf*pinf*(machcoefd*machcoef+machcoef*machcoefd))/(&
&           gammainf*pinf*machcoef*machcoef)**2)
          tmp = two/(gammainf*pinf*machcoef*machcoef)
          cpd = tmpd*(plocal-pinf) + tmp*(plocald-pinfd)
          cp = tmp*(plocal-pinf)
          sigma = 1.4
          sensor1d = -cpd
          sensor1 = -cp - sigma
          sensor1d = -((-(one*2*10*sensor1d*exp(-(2*10*sensor1))))/(one+&
&           exp(-(2*10*sensor1)))**2)
          sensor1 = one/(one+exp(-(2*10*sensor1)))
          sensor1d = sensor1d*cellarea + sensor1*cellaread
          sensor1 = sensor1*cellarea
          cavitationd = cavitationd + sensor1d
          cavitation = cavitation + sensor1
        end do
!
!          **************************************************************
!          *                                                            *
!          * integration of the viscous forces.                         *
!          * only for viscous boundaries.                               *
!          *                                                            *
!          **************************************************************
!
        if (viscoussubface) then
! initialize dwall for the laminar case and set the pointer
! for the unit normals.
          dwall = zero
! replace norm with bcdata norm - peter lyu
!norm => bcdata(nn)%norm
! loop over the quadrilateral faces of the subface and
! compute the viscous contribution to the force and
! moment and update the maximum value of y+.
          do ii=0,(bcdata(nn)%jnend-bcdata(nn)%jnbeg)*(bcdata(nn)%inend-&
&             bcdata(nn)%inbeg)-1
            i = mod(ii, bcdata(nn)%inend - bcdata(nn)%inbeg) + bcdata(nn&
&             )%inbeg + 1
            j = ii/(bcdata(nn)%inend-bcdata(nn)%inbeg) + bcdata(nn)%&
&             jnbeg + 1
! store the viscous stress tensor a bit easier.
            tauxxd = viscsubfaced(nn)%tau(i, j, 1)
            tauxx = viscsubface(nn)%tau(i, j, 1)
            tauyyd = viscsubfaced(nn)%tau(i, j, 2)
            tauyy = viscsubface(nn)%tau(i, j, 2)
            tauzzd = viscsubfaced(nn)%tau(i, j, 3)
            tauzz = viscsubface(nn)%tau(i, j, 3)
            tauxyd = viscsubfaced(nn)%tau(i, j, 4)
            tauxy = viscsubface(nn)%tau(i, j, 4)
            tauxzd = viscsubfaced(nn)%tau(i, j, 5)
            tauxz = viscsubface(nn)%tau(i, j, 5)
            tauyzd = viscsubfaced(nn)%tau(i, j, 6)
            tauyz = viscsubface(nn)%tau(i, j, 6)
! compute the viscous force on the face. a minus sign
! is now present, due to the definition of this force.
            fxd = -(fact*((tauxxd*ssi(i, j, 1)+tauxx*ssid(i, j, 1)+&
&             tauxyd*ssi(i, j, 2)+tauxy*ssid(i, j, 2)+tauxzd*ssi(i, j, 3&
&             )+tauxz*ssid(i, j, 3))*scaledim+(tauxx*ssi(i, j, 1)+tauxy*&
&             ssi(i, j, 2)+tauxz*ssi(i, j, 3))*scaledimd))
            fx = -(fact*(tauxx*ssi(i, j, 1)+tauxy*ssi(i, j, 2)+tauxz*ssi&
&             (i, j, 3))*scaledim)
            fyd = -(fact*((tauxyd*ssi(i, j, 1)+tauxy*ssid(i, j, 1)+&
&             tauyyd*ssi(i, j, 2)+tauyy*ssid(i, j, 2)+tauyzd*ssi(i, j, 3&
&             )+tauyz*ssid(i, j, 3))*scaledim+(tauxy*ssi(i, j, 1)+tauyy*&
&             ssi(i, j, 2)+tauyz*ssi(i, j, 3))*scaledimd))
            fy = -(fact*(tauxy*ssi(i, j, 1)+tauyy*ssi(i, j, 2)+tauyz*ssi&
&             (i, j, 3))*scaledim)
            fzd = -(fact*((tauxzd*ssi(i, j, 1)+tauxz*ssid(i, j, 1)+&
&             tauyzd*ssi(i, j, 2)+tauyz*ssid(i, j, 2)+tauzzd*ssi(i, j, 3&
&             )+tauzz*ssid(i, j, 3))*scaledim+(tauxz*ssi(i, j, 1)+tauyz*&
&             ssi(i, j, 2)+tauzz*ssi(i, j, 3))*scaledimd))
            fz = -(fact*(tauxz*ssi(i, j, 1)+tauyz*ssi(i, j, 2)+tauzz*ssi&
&             (i, j, 3))*scaledim)
! compute the coordinates of the centroid of the face
! relative from the moment reference point. due to the
! usage of pointers for xx and offset of 1 is present,
! because x originally starts at 0.
            xcd = fourth*(xxd(i, j, 1)+xxd(i+1, j, 1)+xxd(i, j+1, 1)+xxd&
&             (i+1, j+1, 1)) - refpointd(1)
            xc = fourth*(xx(i, j, 1)+xx(i+1, j, 1)+xx(i, j+1, 1)+xx(i+1&
&             , j+1, 1)) - refpoint(1)
            ycd = fourth*(xxd(i, j, 2)+xxd(i+1, j, 2)+xxd(i, j+1, 2)+xxd&
&             (i+1, j+1, 2)) - refpointd(2)
            yc = fourth*(xx(i, j, 2)+xx(i+1, j, 2)+xx(i, j+1, 2)+xx(i+1&
&             , j+1, 2)) - refpoint(2)
            zcd = fourth*(xxd(i, j, 3)+xxd(i+1, j, 3)+xxd(i, j+1, 3)+xxd&
&             (i+1, j+1, 3)) - refpointd(3)
            zc = fourth*(xx(i, j, 3)+xx(i+1, j, 3)+xx(i, j+1, 3)+xx(i+1&
&             , j+1, 3)) - refpoint(3)
! update the viscous force and moment coefficients.
            cfvd(1) = cfvd(1) + fxd
            cfv(1) = cfv(1) + fx
            cfvd(2) = cfvd(2) + fyd
            cfv(2) = cfv(2) + fy
            cfvd(3) = cfvd(3) + fzd
            cfv(3) = cfv(3) + fz
            mxd = ycd*fz + yc*fzd - zcd*fy - zc*fyd
            mx = yc*fz - zc*fy
            myd = zcd*fx + zc*fxd - xcd*fz - xc*fzd
            my = zc*fx - xc*fz
            mzd = xcd*fy + xc*fyd - ycd*fx - yc*fxd
            mz = xc*fy - yc*fx
            cmvd(1) = cmvd(1) + mxd
            cmv(1) = cmv(1) + mx
            cmvd(2) = cmvd(2) + myd
            cmv(2) = cmv(2) + my
            cmvd(3) = cmvd(3) + mzd
            cmv(3) = cmv(3) + mz
! save the face based forces for the slice operations
            bcdatad(nn)%fv(i, j, 1) = fxd
            bcdata(nn)%fv(i, j, 1) = fx
            bcdatad(nn)%fv(i, j, 2) = fyd
            bcdata(nn)%fv(i, j, 2) = fy
            bcdatad(nn)%fv(i, j, 3) = fzd
            bcdata(nn)%fv(i, j, 3) = fz
! compute the tangential component of the stress tensor,
! which is needed to monitor y+. the result is stored
! in fx, fy, fz, although it is not really a force.
! as later on only the magnitude of the tangential
! component is important, there is no need to take the
! sign into account (it should be a minus sign).
            fx = tauxx*bcdata(nn)%norm(i, j, 1) + tauxy*bcdata(nn)%norm(&
&             i, j, 2) + tauxz*bcdata(nn)%norm(i, j, 3)
            fy = tauxy*bcdata(nn)%norm(i, j, 1) + tauyy*bcdata(nn)%norm(&
&             i, j, 2) + tauyz*bcdata(nn)%norm(i, j, 3)
            fz = tauxz*bcdata(nn)%norm(i, j, 1) + tauyz*bcdata(nn)%norm(&
&             i, j, 2) + tauzz*bcdata(nn)%norm(i, j, 3)
            fn = fx*bcdata(nn)%norm(i, j, 1) + fy*bcdata(nn)%norm(i, j, &
&             2) + fz*bcdata(nn)%norm(i, j, 3)
            fx = fx - fn*bcdata(nn)%norm(i, j, 1)
            fy = fy - fn*bcdata(nn)%norm(i, j, 2)
            fz = fz - fn*bcdata(nn)%norm(i, j, 3)
! compute the local value of y+. due to the usage
! of pointers there is on offset of -1 in dd2wall..
            if (equations .eq. ransequations) then
              dwall = dd2wall(i-1, j-1)
              rho = half*(ww2(i, j, irho)+ww1(i, j, irho))
              mul = half*(rlv2(i, j)+rlv1(i, j))
              arg1 = fx*fx + fy*fy + fz*fz
              result1 = sqrt(arg1)
              arg2 = rho*result1
              result2 = sqrt(arg2)
              yplus = result2*dwall/mul
              if (yplusmax .lt. yplus) then
                yplusmax = yplus
              else
                yplusmax = yplusmax
              end if
            end if
          end do
        else
! if we had no viscous force, set the viscous component to zero
          bcdatad(nn)%fv = 0.0_8
          bcdata(nn)%fv = zero
        end if
        call resetbcpointers(nn, .true.)
      end if
    else if ((bctype(nn) .eq. eulerwall .or. bctype(nn) .eq. &
&       nswalladiabatic) .or. bctype(nn) .eq. nswallisothermal) then
! if it wasn't included, but still a wall...zero
      bcdatad(nn)%area = 0.0_8
      bcdata(nn)%area = zero
      bcdatad(nn)%fp = 0.0_8
      bcdata(nn)%fp = zero
      bcdatad(nn)%fv = 0.0_8
      bcdata(nn)%fv = zero
    end if
  end do bocos
! currently the coefficients only contain the surface integral
! of the pressure tensor. these values must be scaled to
! obtain the correct coefficients.
  factd = -(two*surfaceref*lref**2*(((gammainfd*pinf+gammainf*pinfd)*&
&   scaledim+gammainf*pinf*scaledimd)*machcoef**2+gammainf*pinf*scaledim&
&   *(machcoefd*machcoef+machcoef*machcoefd))/(gammainf*pinf*machcoef*&
&   machcoef*surfaceref*lref*lref*scaledim)**2)
  fact = two/(gammainf*pinf*machcoef*machcoef*surfaceref*lref*lref*&
&   scaledim)
  cfpd(1) = cfpd(1)*fact + cfp(1)*factd
  cfp(1) = cfp(1)*fact
  cfpd(2) = cfpd(2)*fact + cfp(2)*factd
  cfp(2) = cfp(2)*fact
  cfpd(3) = cfpd(3)*fact + cfp(3)*factd
  cfp(3) = cfp(3)*fact
  cfvd(1) = cfvd(1)*fact + cfv(1)*factd
  cfv(1) = cfv(1)*fact
  cfvd(2) = cfvd(2)*fact + cfv(2)*factd
  cfv(2) = cfv(2)*fact
  cfvd(3) = cfvd(3)*fact + cfv(3)*factd
  cfv(3) = cfv(3)*fact
  factd = (factd*lengthref*lref-fact*lref*lengthrefd)/(lengthref*lref)**&
&   2
  fact = fact/(lengthref*lref)
  cmpd(1) = cmpd(1)*fact + cmp(1)*factd
  cmp(1) = cmp(1)*fact
  cmpd(2) = cmpd(2)*fact + cmp(2)*factd
  cmp(2) = cmp(2)*fact
  cmpd(3) = cmpd(3)*fact + cmp(3)*factd
  cmp(3) = cmp(3)*fact
  cmvd(1) = cmvd(1)*fact + cmv(1)*factd
  cmv(1) = cmv(1)*fact
  cmvd(2) = cmvd(2)*fact + cmv(2)*factd
  cmv(2) = cmv(2)*fact
  cmvd(3) = cmvd(3)*fact + cmv(3)*factd
  cmv(3) = cmv(3)*fact
end subroutine forcesandmoments_d
