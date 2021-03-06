module deformation
  use string
  use precision
  use param
  implicit none
  
  ! Pointers to variable in data
  real(WP), dimension(:,:,:), pointer :: U
  real(WP), dimension(:,:,:), pointer :: V
  real(WP), dimension(:,:,:), pointer :: W
  real(WP), dimension(:,:,:), pointer :: G
  
end module deformation

! ==================== !
! Create the grid/mesh !
! ==================== !
subroutine deformation_grid
  use deformation
  use parser
  implicit none
  integer :: i,j,k
  
  ! Read in the size of the domain
  call parser_read('Number of points',nx)
  ny = nx
  nz = 1
  
  ! Set the periodicity
  xper = 0
  yper = 0
  zper = 1
  
  ! Cartesian
  icyl = 0
  
  ! Allocate the arrays
  allocate(x(nx+1) ,y(ny+1) ,z(nz+1))
  allocate(xm(nx+1),ym(ny+1),zm(nz+1))
  allocate(mask(nx,ny))
  
  ! Create the grid
  do i=1,nx+1
     x(i) = real(i-1,WP)/real(nx,WP)
  end do
  do j=1,ny+1
     y(j) = real(j-1,WP)/real(nx,WP)
  end do
  do k=1,nz+1
     z(k) = real(k-1,WP)/real(nx,WP)
  end do
  
  ! Create the mid points
  do i=1,nx
     xm(i) = 0.5_WP*(x(i)+x(i+1))
  end do
  do j=1,ny
     ym(j) = 0.5_WP*(y(j)+y(j+1))
  end do
  do k=1,nz
     zm(k) = 0.5_WP*(z(k)+z(k+1))
  end do
  
  ! Create the masks
  mask = 0
  
  return
end subroutine deformation_grid


! ========================= !
! Create the variable array !
! ========================= !
subroutine deformation_data
  use deformation
  use parser
  use math
  implicit none
  
  integer :: i,j,k
  
  ! Allocate the array data
  nvar = 4
  allocate(data(nx,ny,nz,nvar))
  allocate(names(nvar))
  
  ! Link the pointers
  U => data(:,:,:,1); names(1) = 'U'
  V => data(:,:,:,2); names(2) = 'V'
  W => data(:,:,:,3); names(3) = 'W'
  G => data(:,:,:,4); names(4) = 'G'
  
  ! Set velocity
  do k=1,nz
     do j=1,ny
        do i=1,nx
           U(i,j,k) = -2.0_WP*sin(Pi*x(i))**2*sin(Pi*ym(j))*cos(Pi*ym(j))
           V(i,j,k) =  2.0_WP*sin(Pi*y(j))**2*sin(Pi*xm(i))*cos(Pi*xm(i))
           W(i,j,k) =  0.0_WP
        end do
     end do
  end do
  
  ! Set G
  do k=1,nz
     do j=1,ny
        do i=1,nx
           G(i,j,k) = 0.15_WP-sqrt((xm(i)-0.5_WP)**2+(ym(j)-0.75_WP)**2)
        end do
     end do
  end do
  
  return
end subroutine deformation_data
