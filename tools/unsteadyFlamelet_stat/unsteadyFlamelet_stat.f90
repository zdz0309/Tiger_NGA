program unsteadyFlamelet_stat
  use precision
  use string
  use fileio
  implicit none

  ! Arrays for needed variables (velocity, dissipation rate, scalar mean, scalar variance)
  real(WP), dimension(:,:), pointer :: U
  real(WP), dimension(:,:), pointer :: RHO
  real(WP), dimension(:,:), pointer :: CHI
  real(WP), dimension(:,:), pointer :: ZMIX
  real(WP), dimension(:,:), pointer :: ZVAR
  real(WP), dimension(:,:), pointer :: ZMIXZMIX
  real(WP), dimension(:,:), pointer :: TEMP
  real(WP), dimension(:,:), pointer :: PROG
  real(WP), dimension(:,:), pointer :: PAH
!  real(WP), dimension(:,:), pointer :: PAH_S
  real(WP), dimension(:,:), pointer :: FV
  real(WP), dimension(:,:), pointer :: data

  integer :: nx,ny,nz,nvar
  integer :: xper,yper,zper
  integer :: icyl
  character(len=str_medium), dimension(:), pointer :: names
  integer :: iunit,ierr,var
  character(len=str_medium) :: statfilename,configfilename,directory,config,filename
  real(WP) :: dt,time
  real(WP), dimension(:), pointer :: x,y,z,xm,ym,zm
  integer, dimension(:,:), pointer :: mask

  real(WP) :: Zst

  real(WP), dimension(:), pointer :: ltime
  real(WP), dimension(:), pointer :: CHIst

  integer, parameter :: NBins = 40

  real(WP), dimension(:), pointer :: Zpdf
  real(WP), dimension(:,:), pointer :: CHIpdf

  real(WP), dimension(:,:,:),pointer :: SCs  ! SD
  real(WP), dimension(:,:),pointer :: XC2H2  ! SD
  real(WP), dimension(:,:),pointer :: XA1  ! SD
  real(WP), dimension(:,:),pointer :: XA2  ! SD
  real(WP), dimension(:,:),pointer :: dp  ! SD
  real(WP), dimension(:,:),pointer :: nums  ! SD
  real(WP), dimension(:,:),pointer :: MW ! SD

  integer :: i,j,k,nsc

  integer :: index_vel,index_rho,index_chi,index_zmix,index_zvar,index_zmix2,index_zmixzmix,index_temp,index_co,index_co2,index_h2,index_h2o,index_pah,index_fv
  logical :: vel_present,rho_present,chi_present,zmix_present,zvar_present,zmix2_present,zmixzmix_present,temp_present,co_present,co2_present,h2_present,h2o_present,pah_present,fv_present

  ! Read file name from standard input
  print*, '============================'
  print*, '| ARTS - unsteady Flamelet |'
  print*, '============================'
  print*
  print "(a15,$)", " stat file : "
  read "(a)", statfilename
  print "(a15,$)", " config file : "
  read "(a)", configfilename
  print "(a13,$)", " directory : "
  read "(a)", directory
  print "(a12,$)", " Z stoich : "
  read "(f)", Zst
  print*

  index_vel = -1
  index_rho = -1
  index_chi = -1
  index_zmix = -1
  index_zvar = -1
  index_zmix2 = -1
  index_temp = -1
  index_co = -1
  index_co2 = -1
  index_h2 = -1
  index_h2o = -1
  index_pah = -1
!!$  index_pah_s = -1
  index_fv = -1

  vel_present = .false.
  rho_present = .false.
  chi_present = .false.
  zmix_present = .false.
  zvar_present = .false.
  zmix2_present = .false.
  zmixzmix_present = .false.
  temp_present = .false.
  co_present = .false.
  co2_present = .false.
  h2_present = .false.
  h2o_present = .false.
  pah_present = .false.
  fv_present = .false.

  ! ** Open the stat file to read **
  call BINARY_FILE_OPEN(iunit,trim(statfilename),"r",ierr)

  ! Read sizes
  call BINARY_FILE_READ(iunit,nx,1,kind(nx),ierr)
  call BINARY_FILE_READ(iunit,ny,1,kind(ny),ierr)
  call BINARY_FILE_READ(iunit,nz,1,kind(nz),ierr)
  call BINARY_FILE_READ(iunit,nvar,1,kind(nvar),ierr)

  ! Read additional stuff
  call BINARY_FILE_READ(iunit,dt,1,kind(dt),ierr)
  call BINARY_FILE_READ(iunit,time,1,kind(dt),ierr)

  ! Read variable names
  allocate(names(nvar))
  do var=1,nvar
     call BINARY_FILE_READ(iunit,names(var),str_medium,kind(names),ierr)
  end do

  ! Find the index of the needed variables
  do var=1,nvar
!!$     select case(trim(names(var)))
!!$     case ('U')
!!$        print*, "axial velocity found"
!!$        index_vel = var
!!$        vel_present = .true.
!!$     case ('RHO')
!!$        print*, "density found"
!!$        index_rho = var
!!$        rho_present = .true.
!!$     case ('CHI')
!!$        print*, "dissipation rate found"
!!$        index_chi = var
!!$        chi_present = .true.
!!$     case ('SC-ZMIX')
!!$        print*, "mixture fraction found"
!!$        index_zmix = var
!!$        zmix_present = .true.
!!$     case ('ZVAR')
!!$        print*, "dynamic mixture fraction variance found"
!!$        index_zvar = var
!!$        zvar_present = .true.
!!$     case ('SC-ZVAR')
!!$        print*, "transported mixture fraction variance found"
!!$        index_zvar = var
!!$        zvar_present = .true.
!!$     case ('SC-ZMIX2')
!!$        print*, "transported mixture fraction squared found"
!!$        index_zmix2 = var
!!$        zmix2_present = .true.
!!$     case ('SC^2-ZMIX')
!!$        print*, "square of mixture fraction found"
!!$        index_zmixzmix = var
!!$        zmixzmix_present = .true.
!!$     case ('T')
!!$        print*, "temperature found"
!!$        index_temp = var
!!$        temp_present = .true.
!!$     case ('Y_CO')
!!$        print*, "CO mass fraction found"
!!$        index_co = var
!!$        co_present = .true.
!!$     case ('Y_CO2')
!!$        print*, "CO2 mass fraction found"
!!$        index_co2 = var
!!$        co2_present = .true.
!!$     case ('Y_H2')
!!$        print*, "H2 mass fraction found"
!!$        index_h2 = var
!!$        h2_present = .true.
!!$     case ('Y_H2O')
!!$        print*, "H2O mass fraction found"
!!$        index_h2o = var
!!$        h2o_present = .true.
!!$     case ('Y_PAH')
!!$        print*, "PAH mass fraction found"
!!$        index_pah = var
!!$        pah_present = .true.

        ! SD
        select case(trim(names(var)))
     case ('U')
        print*, "axial velocity found"
        index_vel = var
        vel_present = .true.
     case ('RHO')
        print*, "density found"
        index_rho = var
        rho_present = .true.
     case ('SC-C2H2')
        print*, "C2H2 found"
        index_chi = var
        chi_present = .true.
     case ('SC-ZMIX')
        print*, "mixture fraction found"
        index_zmix = var
        zmix_present = .true.
     case ('ZVAR')
        print*, "dynamic mixture fraction variance found"
        index_zvar = var
        zvar_present = .true.
     case ('SC-ZVAR')
        print*, "transported mixture fraction variance found"
        index_zvar = var
        zvar_present = .true.
     case ('SC-ZMIX2')
        print*, "transported mixture fraction squared found"
        index_zmix2 = var
        zmix2_present = .true.
     case ('SC^2-ZMIX')
        print*, "square of mixture fraction found"
        index_zmixzmix = var
        zmixzmix_present = .true.
     case ('SC-T')
        print*, "temperature found"
        index_temp = var
        temp_present = .true.
     case ('SC-A1XC6H6')
        print*, "A1 found"
        index_co = var
        co_present = .true.
     case ('SC-A2XC10H8')
        print*, "A2 found"
        index_co2 = var
        co2_present = .true.
     case ('dp')
        print*, "dp found"
        index_h2 = var
        h2_present = .true.
     case ('N')
        print*, "N found"
        index_h2o = var
        h2o_present = .true.
     case ('Y_PAH')
        print*, "PAH mass fraction found"
        index_pah = var
        pah_present = .true.
!!$     case ('Y_PAH_S')
!!$        print*, "PAH mass fraction (steady model) found"
!!$        index_pah_s = var
!!$        pah_s_present = .true.
     case ('fV')
        print*, "volume fraction found"
        index_fv = var
        fv_present = .true.
     end select
  end do

  if (zmix2_present .and. .not.zmixzmix_present) then
     print*, 'If mixture fraction squared is to be used then the squared of the mixture fraction is needed'
  end if

  ! Allocate the variable
  allocate(data(nx,ny))
  allocate(U(nx,ny))
  allocate(RHO(nx,ny))
  allocate(CHI(nx,ny))
  allocate(ZMIX(nx,ny))
  if (zmix2_present) allocate(ZMIXZMIX(nx,ny))
  allocate(ZVAR(nx,ny))
  allocate(TEMP(nx,ny))
  allocate(PROG(nx,ny))
  allocate(PAH(nx,ny))
!  allocate(PAH_S(nx,ny))
  allocate(FV(nx,ny))
  allocate(SCs(nx,ny,46)) ! SD species+1

  ! SD
  allocate(XC2H2(nx,ny))
  allocate(XA1(nx,ny))
  allocate(XA2(nx,ny))
  allocate(dp(nx,ny))
  allocate(nums(nx,ny))
  allocate(MW(nx,ny))
  ! SD

  ! Initialize the progress variable
  PROG = 0.0_WP

  ! Read the needed data
  ! Initialize the scalar indicator
  nsc = 0
  do var=1,nvar
     call BINARY_FILE_READ(iunit,data,nx*ny*nz,kind(data),ierr)
     if (var.eq.index_vel) then
        do j=1,ny
           do i=1,nx
              U(i,j) = data(i,j)
           end do
        end do
     end if
     if (var.eq.index_rho) then
        do j=1,ny
           do i=1,nx
              RHO(i,j) = data(i,j)
           end do
        end do
     end if
!!$     if (var.eq.index_chi) then
!!$        do j=1,ny
!!$           do i=1,nx
!!$              CHI(i,j) = data(i,j)
!!$           end do
!!$        end do
!!$     end if
     if (var.eq.index_zmix) then
        do j=1,ny
           do i=1,nx
              ZMIX(i,j) = data(i,j)
           end do
        end do
     end if
     if (var.eq.index_zvar .or. var.eq.index_zmix2) then
        do j=1,ny
           do i=1,nx
              ZVAR(i,j) = data(i,j)
           end do
        end do
     end if
     if (zmix2_present .and. var.eq.index_zmixzmix) then
        do j=1,ny
           do i=1,nx
              ZMIXZMIX(i,j) = data(i,j)
           end do
        end do
     end if
     if (var.eq.index_temp) then
        do j=1,ny
           do i=1,nx
              TEMP(i,j) = data(i,j)
              MW(i,j) = RHO(i,j) * 8.314_WP * TEMP(i,j) / 101.32_WP
           end do
        end do
     end if
     
     ! SD
     if (var.eq.index_chi) then
        do j=1,ny
           do i=1,nx
              XC2H2(i,j) = data(i,j)
           end do
        end do
     end if     
     if (var.eq.index_co) then
        do j=1,ny
           do i=1,nx
              XA1(i,j) = data(i,j)
           end do
        end do
     end if
     if (var.eq.index_co2) then
        do j=1,ny
           do i=1,nx
              XA2(i,j) = data(i,j)
           end do
        end do
     end if
     if (var.eq.index_h2) then
        do j=1,ny
           do i=1,nx
              dp(i,j) = data(i,j)
           end do
        end do
     end if
     if (var.eq.index_h2o) then
        do j=1,ny
           do i=1,nx
              nums(i,j) = data(i,j)
           end do
        end do
        ! SD END
!!$     if (var.eq.index_co) then
!!$        do j=1,ny
!!$           do i=1,nx
!!$              PROG(i,j) = PROG(i,j) + data(i,j)
!!$           end do
!!$        end do
!!$     end if
!!$     if (var.eq.index_co2) then
!!$        do j=1,ny
!!$           do i=1,nx
!!$              PROG(i,j) = PROG(i,j) + data(i,j)
!!$           end do
!!$        end do
!!$     end if
!!$     if (var.eq.index_h2) then
!!$        do j=1,ny
!!$           do i=1,nx
!!$              PROG(i,j) = PROG(i,j) + data(i,j)
!!$           end do
!!$        end do
!!$     end if
!!$     if (var.eq.index_h2o) then
!!$        do j=1,ny
!!$           do i=1,nx
!!$              PROG(i,j) = PROG(i,j) + data(i,j)
!!$           end do
!!$        end do
     end if
     if (var.eq.index_pah) then
        do j=1,ny
           do i=1,nx
              PAH(i,j) = data(i,j)
           end do
        end do
     end if
!!$     if (var.eq.index_pah_s) then
!!$        do j=1,ny
!!$           do i=1,nx
!!$              PAH_S(i,j) = data(i,j)
!!$           end do
!!$        end do
!!$     end if
     if (var.eq.index_fv) then
        do j=1,ny
           do i=1,nx
              FV(i,j) = data(i,j)
           end do
        end do
     end if
     
     ! SD
     if (var.ge.15 .and. var.le.195 .and. mod(var,4).eq.3) then
        print*,'Scalar',var
        nsc = nsc + 1
        print*,'Species Number',nsc
        do j=1,ny
           do i=1,nx
              SCs(i,j,nsc) = data(i,j)
           end do
        end do
     end if
     ! SD END
  end do
  print*,'Number of species:',nsc
  ! Close the files
  call BINARY_FILE_CLOSE(iunit,ierr)

  ! Compute the variance from the mixture fraction squared
  if (index_zmix2.gt.-1) then
     index_zvar = index_zmix2
     zvar_present = .true.
     ZVAR = ZVAR - ZMIXZMIX
  end if

  ! Exit if not all needed variables found
  if (.not.(vel_present .and. chi_present .and. zmix_present .and. zvar_present)) then
     print*, 'Not all needed variables were found in the data file'
  end if

  ! SD
  ! Compute mole fractions
  XC2H2 = XC2H2 * MW / 26.0_WP
  XA1 = XA1 * MW / 78.0_WP
  XA2 = XA2 * MW / 128.0_WP
  ! SD END

  ! ** Open the config file to read **
  call BINARY_FILE_OPEN(iunit,trim(configfilename),"r",ierr)

  ! Read sizes
  call BINARY_FILE_READ(iunit,config,str_medium,kind(config),ierr)
  call BINARY_FILE_READ(iunit,icyl,1,kind(icyl),ierr)
  call BINARY_FILE_READ(iunit,xper,1,kind(xper),ierr)
  call BINARY_FILE_READ(iunit,yper,1,kind(yper),ierr)
  call BINARY_FILE_READ(iunit,zper,1,kind(zper),ierr)
  call BINARY_FILE_READ(iunit,nx,1,kind(nx),ierr)
  call BINARY_FILE_READ(iunit,ny,1,kind(ny),ierr)
  call BINARY_FILE_READ(iunit,nz,1,kind(nz),ierr)

  if (icyl.ne.1) print*, 'Only for cylindrical coordinates'
  
  ! Read grid field
  allocate(x(nx+1),y(ny+1),z(nz+1))
  allocate(mask(nx,ny))
  call BINARY_FILE_READ(iunit,x,nx+1,kind(x),ierr)
  call BINARY_FILE_READ(iunit,y,ny+1,kind(y),ierr)
  call BINARY_FILE_READ(iunit,z,nz+1,kind(z),ierr)
  call BINARY_FILE_READ(iunit,mask,nx*ny,kind(mask),ierr)
  
  ! Close the file
  call BINARY_FILE_CLOSE(iunit,ierr)

  allocate(xm(nx),ym(ny),zm(nz))

  do i=1,nx
     xm(i) = 0.5_WP*(x(i)+x(i+1))
  end do
  do j=1,ny
     ym(j) = 0.5_WP*(y(j)+y(j+1))
  end do
  do k=1,nz
     zm(k) = 0.5_WP*(z(k)+z(k+1))
  end do

  call system("mkdir -p "//trim(directory))

  allocate(ltime(nx))
  allocate(CHIst(nx))

  call compute_ltime(xm,ZMIX,U,nx,ny,Zst,ltime)
  call compute_chist(xm,ZMIX,CHI,nx,ny,Zst,CHIst)

  ! Output the axial profile file
  filename = trim(directory) // '/CA.in'
  iunit = iopen()
  open(iunit,file=filename,form="formatted",iostat=ierr)
  write(iunit,'(10000a)') 'RPM = -1'
  write(iunit,'(10000a)') 'VarsIn = 9'
  write(iunit,'(10000a)') 'Time(s) ', 'x ', 'Pressure(Pa) ', 'TOx(K) ', 'TFuel(K) ', 'Sci(1/s) ', 'ZR ', 'ZMean ', 'ZVar '
  do i=1,nx
     if (xm(i).gt.0.0_WP) then
        write(iunit,'(10000ES20.12)') ltime(i), xm(i), 1.01320E+05, 293.0, 293.0, CHIst(i), 1.0, ZMIX(i,1), ZVAR(i,1)
     end if
  end do
  close(iclose(iunit))

  ! Output the dissipation rate pdf as a function of the Lagrangian time
  allocate(Zpdf(NBins+1))
  call compute_Zpdf(Zpdf,NBins)
  filename = trim(directory) //'/zi.dat'
  iunit = iopen()
  open(iunit,file=filename,form="formatted",iostat=ierr)
  do i=1,NBins+1
     write(iunit,'(10000F6.4)') Zpdf(i)
  end do
  close(iclose(iunit))

  allocate(CHIpdf(nx,NBins+1))
  call compute_chiofZ(Zpdf,CHIpdf,CHI,ZMIX,nx,ny,NBins)
  filename = trim(directory) //'/chi.dat'
  iunit = iopen()
  open(iunit,file=filename,form="formatted",iostat=ierr)
  do i=1,nx
     if (xm(i).gt.0.0_WP) then
        do j=1,NBins+1
           write(iunit,'(10000ES20.12)') CHIpdf(i,j)
        end do
     end if
  end do
  close(iclose(iunit))

  ! Output the Lagrangian time
  filename = trim(directory) //'/Time.dat'
  iunit = iopen()
  open(iunit,file=filename,form="formatted",iostat=ierr)
  do i=1,nx
     if (xm(i).gt.0.0_WP) then
        write(iunit,'(10000ES20.12)') ltime(i)
     end if
  end do
  close(iclose(iunit))

  ! Output the temperature as a function of the Lagrangian time
  if (temp_present) then
     filename = trim(directory) //"/Temp.dat"
     iunit = iopen()
     open(iunit,file=filename,form="formatted",iostat=ierr)
     do i=1,nx
        if (xm(i).gt.0.0_WP) then
           write(iunit,'(3ES20.12)') ltime(i), xm(i), TEMP(i,1)
        end if
     end do
     close(iclose(iunit))
  end if

  ! Output the progress variable as a function of the Lagrangian time
  if (co_present .and. co2_present .and. h2_present .and. h2o_present) then
     filename = trim(directory) //"/Prog.dat"
     iunit = iopen()
     open(iunit,file=filename,form="formatted",iostat=ierr)
     do i=1,nx
        if (xm(i).gt.0.0_WP) then
           write(iunit,'(3ES20.12)') ltime(i), xm(i), PROG(i,1)
        end if
     end do
     close(iclose(iunit))
  end if

  ! Output the aromatic mass fraction as a function of the Lagrangian time
  if (pah_present) then
     filename = trim(directory) //"/PAH.dat"
     iunit = iopen()
     open(iunit,file=filename,form="formatted",iostat=ierr)
     do i=1,nx
        if (xm(i).gt.0.0_WP) then
           write(iunit,'(3ES20.12)') ltime(i), xm(i), PAH(i,1)
        end if
     end do
     close(iclose(iunit))
  end if

!!$  ! Output the aromatic mass fraction (steady model) as a function of the Lagrangian time
!!$  if (pah_s_present) then
!!$     filename = "PAH_S.dat"
!!$     iunit = iopen()
!!$     open(iunit,file=filename,form="formatted",iostat=ierr)
!!$     do i=1,nx
!!$        if (xm(i).gt.0.0_WP) then
!!$           write(iunit,'(3ES20.12)') ltime(i), xm(i), PAH_S(i,1)
!!$        end if
!!$     end do
!!$     close(iclose(iunit))
!!$  end if

  ! Output the soot volume fraction as a function of the Lagrangian time
  if (fv_present) then
     filename = trim(directory) //"/FV.dat"
     iunit = iopen()
     open(iunit,file=filename,form="formatted",iostat=ierr)
     do i=1,nx
        if (xm(i).gt.0.0_WP) then
           write(iunit,'(3ES20.12)') ltime(i), xm(i), FV(i,1)
        end if
     end do
     close(iclose(iunit))
  end if

  ! SD
  ! Output the start profile for unsteady flamelet
  if (nsc.gt.1) then
     filename = trim(directory) //"/ScalarT.dat"
     iunit = iopen()
     open(iunit,file=filename,form="formatted",iostat=ierr)
     loop1:do i=1,nx
        if (xm(i).gt.0.0_WP) then
           do j=1,ny
              write(iunit,'(10000ES20.12)') ZMIX(i,j), SCs(i,j,:)
           end do
           exit loop1
        end if
     end do loop1
     close(iclose(iunit))
  end if
  ! SD END

  ! SD
  ! Output fv_max in y at different x locations
  if (fv_present) then
     filename = trim(directory) //"/FV_max.dat"
     iunit = iopen()
     open(iunit,file=filename,form="formatted",iostat=ierr)
     do i=1,nx
        if (xm(i).gt.0.0_WP) then
           write(iunit,'(3ES20.12)') xm(i), maxval(FV(i,:))
        end if
     end do
     close(iclose(iunit))
  end if
  ! SD END

  ! SD
  ! Output mole fractions
  if (fv_present) then
     filename = trim(directory) //"/OUT_C2H2.dat"
     iunit = iopen()
     open(iunit,file=filename,form="formatted",iostat=ierr)
     write(iunit,'(200ES20.12)') 0.0_WP, ym(1:ny)*1e3_WP
     do i=1,nx
        if (xm(i).gt.0.0_WP) then
           write(iunit,'(200ES20.12)') xm(i)*1e3_WP, XC2H2(i,1:ny)
        end if
     end do
     close(iclose(iunit))
     filename = trim(directory) //"/OUT_A1.dat"
     iunit = iopen()
     open(iunit,file=filename,form="formatted",iostat=ierr)
     write(iunit,'(200ES20.12)') 0.0_WP, ym(1:ny)*1e3_WP
     do i=1,nx
        if (xm(i).gt.0.0_WP) then
           write(iunit,'(200ES20.12)') xm(i)*1e3_WP, XA1(i,1:ny)
        end if
     end do
     close(iclose(iunit))
     filename = trim(directory) //"/OUT_A2.dat"
     iunit = iopen()
     open(iunit,file=filename,form="formatted",iostat=ierr)
     write(iunit,'(200ES20.12)') 0.0_WP, ym(1:ny)*1e3_WP
     do i=1,nx
        if (xm(i).gt.0.0_WP) then
           write(iunit,'(200ES20.12)') xm(i)*1e3_WP, XA2(i,1:ny)
        end if
     end do
     close(iclose(iunit))
     filename = trim(directory) //"/OUT_T.dat"
     iunit = iopen()
     open(iunit,file=filename,form="formatted",iostat=ierr)
     write(iunit,'(200ES20.12)') 0.0_WP, ym(1:ny)*1e3_WP
     do i=1,nx
        if (xm(i).gt.0.0_WP) then
           write(iunit,'(200ES20.12)') xm(i)*1e3_WP, TEMP(i,1:ny)
        end if
     end do
     close(iclose(iunit))
     filename = trim(directory) //"/OUT_fv.dat"
     iunit = iopen()
     open(iunit,file=filename,form="formatted",iostat=ierr)
     write(iunit,'(200ES20.12)') 0.0_WP, ym(1:ny)*1e3_WP
     do i=1,nx
        if (xm(i).gt.0.0_WP) then
           write(iunit,'(200ES20.12)') xm(i)*1e3_WP, FV(i,1:ny)*1e6_WP
        end if
     end do
     close(iclose(iunit))
     filename = trim(directory) //"/OUT_dp.dat"
     iunit = iopen()
     open(iunit,file=filename,form="formatted",iostat=ierr)
     write(iunit,'(200ES20.12)') 0.0_WP, ym(1:ny)*1e3_WP
     do i=1,nx
        if (xm(i).gt.0.0_WP) then
           write(iunit,'(200ES20.12)') xm(i)*1e3_WP, dp(i,1:ny)
        end if
     end do
     close(iclose(iunit))
     filename = trim(directory) //"/OUT_N.dat"
     iunit = iopen()
     open(iunit,file=filename,form="formatted",iostat=ierr)
     write(iunit,'(200ES20.12)') 0.0_WP, ym(1:ny)*1e3_WP
     do i=1,nx
        if (xm(i).gt.0.0_WP) then
           write(iunit,'(200ES20.12)') xm(i)*1e3_WP, nums(i,1:ny)
        end if
     end do
     close(iclose(iunit))
  end if
  ! SD END


end program unsteadyFlamelet_stat


subroutine compute_ltime(xm,ZMIX,U,nx,ny,Zst,ltime)
  use precision
  implicit none

  integer, intent(in) :: nx,ny
  real(WP), dimension(nx,ny), intent(in) :: ZMIX,U
  real(WP), dimension(nx), intent(in) :: xm
  real(WP), intent(in) :: Zst
  real(WP), dimension(nx), intent(out) :: ltime
  integer :: i,j

  real(WP), dimension(nx) :: Ust

  ltime = 0.0_WP
  Ust = 0.0_WP

  do i=1,nx
     if (ZMIX(i,1).gt.Zst) then
        loop1: do j=1,ny
           if (ZMIX(i,j).lt.Zst) then
              Ust(i) = Ust(i) + U(i,j) - (U(i,j)-U(i,j-1))*((ZMIX(i,j)-Zst)/(ZMIX(i,j)-ZMIX(i,j-1)))
              !if (i.eq.2) print*, U(i,j), Zst, ZMIX(i,j)
              exit loop1
           end if
        end do loop1
     else
        Ust(i) = Ust(i) + U(i,1)
     end if
  end do

  do i=1,nx
     if (xm(i).lt.0.0_WP) then
        ltime(i) = 0.0_WP
     elseif (xm(i-1).lt.0.0_WP) then
        ltime(i) = 0.5_WP * (1.0_WP/Ust(i))*(xm(i))
     else
        ltime(i) = ltime(i-1) + 0.5_WP*(1.0_WP/Ust(i)+1.0_WP/Ust(i-1))*(xm(i)-xm(i-1))
     end if
  end do

  return
end subroutine compute_ltime


subroutine compute_Zpdf(Zpdf,NBins)
  use precision
  implicit none
  
  integer, intent(in) :: NBins
  real(WP), dimension(NBins+1), intent(out) :: Zpdf
  integer :: i

  do i=1,NBins+1
     Zpdf(i) = (i-1)*(1.0_WP/real(NBins,WP))
  end do

  return 
end subroutine compute_Zpdf


subroutine compute_chiofZ(Zpdf,CHIpdf,CHI,Z,nx,ny,NBins)
  use precision
  implicit none

  integer, intent(in) :: nx,ny,NBins

  real(WP), dimension(NBins+1), intent(in) :: Zpdf
  real(WP), dimension(nx,NBins+1), intent(out) :: CHIpdf

  real(WP), dimension(nx,ny), intent(in) :: CHI
  real(WP), dimension(nx,ny), intent(in) :: Z
  real(WP), dimension(nx,NBins+1) :: NUMpdf

  integer :: i,j,l,m,n

  real(WP) :: chi_lower, chi_upper, z_lower, z_upper

  CHIpdf = 0.0_WP
  NUMpdf = 0.0_WP

  do i=1,nx
     loop1:do j=1,ny
        loop2:do l=2,NBins+1
           if (Z(i,j).lt.(0.5_WP*(Zpdf(l)+Zpdf(l-1)))) then
              CHIpdf(i,l-1) = CHIpdf(i,l-1) + CHI(i,j)
              NUMpdf(i,l-1) = NUMpdf(i,l-1) + 1.0_WP
              cycle loop1
           end if
        end do loop2
        CHIpdf(i,NBins+1) = CHIpdf(i,NBins+1) + CHI(i,j)
        NUMpdf(i,NBins+1) = NUMpdf(i,NBins+1) + 1.0_WP
     end do loop1
  end do

  do i=1,nx
     do l=1,NBins+1
        if (NUMpdf(i,l).gt.0.0_WP) CHIpdf(i,l) = CHIpdf(i,l) / NUMpdf(i,l)
     end do
     z_lower = -1.0_WP
     z_upper = 2.0_WP
     do l=2,NBins
        if (CHIpdf(i,l).eq.0.0_WP) then
           loop3:do m=l-1,1,-1
              if (CHIpdf(i,m).ne.0.0_WP) then
                 chi_lower = CHIpdf(i,m)
                 z_lower = Zpdf(m)
                 exit loop3
              end if
           end do loop3
           loop4:do n=l+1,NBins+1
              if (CHIpdf(i,n).ne.0.0_WP) then
                 chi_upper = CHIpdf(i,n)
                 z_upper = Zpdf(n)
                 exit loop4
              end if
           end do loop4
           if (z_lower.gt.-0.9_WP .and. z_upper.lt.1.9_WP) then
              CHIpdf(i,l) = chi_lower + (chi_upper-chi_lower)*(Zpdf(l)-z_lower)/(z_upper-z_lower)
           end if
        end if
     end do
  end do

  return
end subroutine compute_chiofZ


subroutine compute_chist(xm,ZMIX,CHI,nx,ny,Zst,CHIst)
  use precision
  implicit none

  integer, intent(in) :: nx,ny
  real(WP), dimension(nx,ny), intent(in) :: ZMIX,CHI
  real(WP), dimension(nx), intent(in) :: xm
  real(WP), intent(in) :: Zst
  real(WP), dimension(nx), intent(out) :: CHIst
  integer :: i,j

  CHIst = 0.0_WP

  do i=1,nx
     if (ZMIX(i,1).gt.Zst) then
        loop1: do j=1,ny
           if (ZMIX(i,j).lt.Zst) then
              CHIst(i) = CHIst(i) + CHI(i,j) - (CHI(i,j)-CHI(i,j-1))*((ZMIX(i,j)-Zst)/(ZMIX(i,j)-ZMIX(i,j-1)))
              !if (i.eq.2) print*, CHI(i,j), ZMIX(i,j)
              exit loop1
           end if
        end do loop1
     else
        CHIst(i) = CHIst(i) + CHI(i,1)
     end if
  end do

  return
end subroutine compute_chist
