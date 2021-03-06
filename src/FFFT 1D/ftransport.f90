program transport
    implicit none
    integer, parameter :: N = 63, Q = 63, niter = 100000
    double precision, parameter :: eps = 1e-10, alpha = 1., g = 1., b = 1.
    double precision, parameter :: pi = 4.D0*DATAN(1.D0)
    double precision, dimension(N+1) :: f0, f1
    double precision, dimension(Q+1,N+1,2) :: zV = 0, wV0 = 0, wV1 = 0
    double precision, dimension(Q+2,N+2,2) :: zU = 0, wU0 = 0, wU1 = 0
		integer, dimension(Q+1,N+1) :: obstacle = 0
		double precision :: t
    double precision, dimension(niter) :: cout, minF, divV
    integer :: i, k, l 
  	character(10) :: charI;
	
	
	!! Initialisation
    f0 = normalise(eps + gauss(0.2d0,0.05d0))
    f1 = normalise(eps + gauss(0.8d0,0.05d0) + 0.4*gauss(0.3d0,0.1d0))
    
    f0 = normalise(eps + indicatrix(0.2d0,0.3d0))
    f1 = normalise(eps + indicatrix(0.6d0,0.9d0))
    
    f0 = normalise(eps + gauss(0.2d0,0.05d0))
    f1 = normalise(eps + gauss(0.8d0,0.05d0))
    
    f0 = normalise(eps + gauss(0.5d0,0.05d0))
    f1 = normalise(eps + gauss(0.5d0,0.05d0))
 		obstacle(8:10,1:60) =	1	
 		obstacle(18:20,4:64) = 1
 		obstacle(38:40,4:64) = 1
 		
 		   
    do i = 1,Q+2
			t = (i-1)/(1.*(Q+1))
			wU0(i,1:N+1,2) = (1-t)*f1 + t*f0
    end do 
    wV0 = interp(wU0)
    zU = wU0; zV = wV0
    
     !! DR
    do i = 1,niter
			wU1 = wU0 + alpha*(projC(2*zU - wU0) - zU)
			wV1 = wV0 + alpha*(proxJ(2*zV - wV0) - zV)
			zU  = projCs(wU1,wV1)
			zV  = interp(zU)

			wU0 = wU1
			wV0 = wV1
		
      cout(i) = J(zV)
			minF(i) = minval(zV(:,:,2))
			divV(i) = sum(div(Zu)**2)
		
        if (modulo(i,1000) .EQ. 0) print *, i, cout(i)       
    end do 
    
	  open(1,file='results/transport.dat')
	  open(2,file='results/obstacle.dat')
    do i = Q+1,1,-1
           write(1,*), zV(i,:,2)      
           write(2,*), obstacle(i,:)  
    end do
    do i = Q+1,1,-1
    	do k = 1,N+1
    !		write(2,*), i,k, obstacle(i,k)
    	end do
    end do
    close(1); close(2)
    
    do l = 1,Q+2
			write(charI,'(I5.5)') Q+3 - l
			open(1,file='results/Transport/'//trim(charI)//'.dat'); 
			write(1,*) "# ", "X ", "T "
				do k = 1,N+2 ! x direction 
					write(1,*) (k-1)/(1.0*N),  zU(l,k,2)
			end do
			close(1)
	  end do 

    open(1,file='results/data.dat');
    write(1,*) "# ", "iter ", "energie ", "minF ", "divV "
    do i = 1,niter
		write(1,*) i, cout(i), minF(i), divV(i)
    end do
    close(1)    
    
    open(1,file='results/f0.dat');
    write(1,*) "# ", "X ", "Y "
    do i = 1,N+1
        write(1,*) (i-1)/(1.0*N), f0(i)
    end do
    close(1)

    open(1,file='results/f1.dat');
    write(1,*) "# ", "X ", "Y "
    do i = 1,N+1
        write(1,*) (i-1)/(1.0*N), f1(i)
    end do
    close(1)

		open(8,file="results/plot.gnu"); 
		write(8,*) 'set dgrid3d ', Q+1, ',', N+1
		close(8);
		
    contains

!! Gauss
    function gauss(mu,sigma) result(f) 
		implicit none
        double precision :: mu, sigma 
        double precision, dimension(N+1) :: f
        integer :: i
        do i = 1,N+1
            f(i) = exp(-0.5*((((i-1)/(1.0*N))-mu)/sigma)**2)
        end do 
    end function gauss

!! Indicatrice 
	function indicatrix(a,b) result(f)
	implicit none
        double precision :: a, b
        double precision, dimension(N+1) :: f, x
        integer :: i
        do i = 1,N+1
            x(i) = (i-1)/(1.*N)
        end do 
        f = 0
        where ((x .GT. a) .AND. (x .LT. b)) f = 1
    end function indicatrix	
	
!! Normalise
    function normalise(f) result(nf) 
	implicit none
	    double precision, dimension(N+1) :: f, nf
        nf = f/sum(f)
    end function

!! Cout 
    function J(w) result(c) 
    implicit none
        double precision, dimension(Q+1,N+1,2) :: w
        double precision :: c
        c = 0.5*sum(w(:,:,1)**2/max(w(:,:,2),eps,1e-10)**b)
    end function J 

!! Proximal de J 
    function proxJ(w) result(pw)
    implicit none
        double precision, dimension(Q+1,N+1,2) :: w, pw
        double precision, dimension(Q+1,N+1) :: mt, ft, x0, x1, poly, dpoly
        integer :: k
        
        mt = w(:,:,1); ft = w(:,:,2);
        x0 = 1; x1 = 2; k = 0;

        do while (maxval(dabs(x0-x1)) .GT. 1e-5  .AND. k .LT. 1500)
            x0 = x1
            if (b .EQ. 1) then ! Cas transport
				poly  = (x0-ft)*(x0+g)**2 - 0.5*g*mt**2
				dpoly = 2*(x0+g)*(x0-ft) + (x0+g)**2
			else if (b .EQ. 0) then ! Interpolation L2
				x1 = ft
				exit
			else 
				poly = x0**(1.0-b)*(x0-ft)*((x0**b+g)**2)-0.5*b*g*mt**2
				dpoly = (1.0-b)*x0**(-b)*(x0-ft)*((x0**b+g)**2) + x0**(1-b)*((x0**b+g)**2 +2*b*(x0-ft)*x0**(b-1)*(x0**b+g) )
			end if
			
			where (x0 .GT. eps) x1 = x0 - poly/dpoly
			where (x0 .LT. eps) x1 = eps		
			
            k = k+1
        end do

        where ((x1 .LT. eps) .OR.  (obstacle .GT. 0)) x1 = eps

        pw(:,:,2) = x1
        pw(:,:,1) = (x1**b)*mt/(x1**b+g) 
    end function proxJ
    
!! Interpolation 
	function interp(U) result(V)
	implicit none 
		double precision, dimension(Q+2,N+2,2) :: U
		double precision, dimension(Q+1,N+1,2) :: V
		V(:,:,1) = U(1:Q+1,1:N+1,1) + U(1:Q+1,2:N+2,1)
		V(:,:,2) = U(1:Q+1,1:N+1,2) + U(2:Q+2,1:N+1,2)
		V = 0.5*V
	end function interp

!! Interpolation adjoint 
	function interpAdj(V) result(U)
		double precision, dimension(Q+2,N+2,2) :: U
		double precision, dimension(Q+1,N+1,2) :: V
		U = 0
		U(1:Q+1,1,1) = V(:,1,1) 
		U(1:Q+1,2:N+1,1) = V(:,2:N+1,1) + V(:,1:N,1)
		U(1:Q+1,N+2,1) = V(:,N+1,1)
		
		U(1,1:N+1,2) = V(1,:,2)
		U(2:Q+1,1:N+1,2) = V(2:Q+1,:,2) + V(1:Q,:,2)
		U(Q+2,1:N+1,2) = V(Q+1,:,2)
		U = 0.5*U 	
	end function interpAdj

!! Projection sur Cs
	function projCs(U,V) result(pU)
	implicit none
		double precision, dimension(Q+2,N+2,2) :: U, b, r, p, Ip, pU
		double precision, dimension(Q+1,N+1,2) :: V
		double precision :: alpha, rnew, rold
		integer :: i 
		b = U + interpAdj(V)
		pU = 0
		r = b - pU - interpAdj(interp(pU))
		p = r
		rold = sum(r*r)
		do i = 1,2*(Q+2)*(N+2)
			Ip = p + interpAdj(interp(p))
			alpha = rold/sum(p*Ip)
			pU = pU + alpha*p
			r = r - alpha*Ip
			rnew = sum(r*r) 
			if (dsqrt(rnew) .LT. 1e-10) exit
			p = r + (rnew/rold)*p
			rold = rnew
		end do 
	end function projCs

!! Divergence 
	function div(U) result(D) 
	implicit none
		double precision, dimension(Q+2,N+2,2) :: U
		double precision, dimension(Q+1,N+1) :: D
		D = (N+1)*(U(1:Q+1,2:N+2,1) - U(1:Q+1,1:N+1,1)) + (Q+1)*(U(2:Q+2,1:N+1,2) - U(1:Q+1,1:N+1,2))
	end function div

!! Adjoint de la divergence 
	function divAdj(D) result(U)
	implicit none
		double precision, dimension(Q+2,N+2,2) :: U
		double precision, dimension(Q+1,N+1) :: D
		U = 0
		
		U(1:Q+1,1,1)     = -D(:,1)
		U(1:Q+1,2:N+1,1) = D(:,1:N) - D(:,2:N+1)
		U(1:Q+1,N+2,1)   = D(:,N+1)
		U(:,:,1) = (N+1)*U(:,:,1)
		
		U(1,1:N+1,2)     = -D(1,:) 
		U(2:Q+1,1:N+1,2) = D(1:Q,:) - D(2:Q+1,:)
		U(Q+2,1:N+1,2)   = D(Q+1,:) 
		U(:,:,2) = (Q+1)*U(:,:,2)
	end function divAdj

!! Projection sur C
	function projC(U) result(pU) 
	implicit none 
		double precision, dimension(Q+2,N+2,2) :: U, pU, gf
		double precision, dimension(Q+1,N+1)   :: D, f	

		U(1  ,1:N+1,2) = f1
		U(Q+2,1:N+1,2) = f0
		
		D = div(U)
		f = poisson(-D)
		
		gf = divAdj(f)
		pU = U
		pU(:,2:N+1,1) = pU(:,2:N+1,1) + gf(:,2:N+1,1);
		pU(2:Q+1,:,2) = pU(2:Q+1,:,2) + gf(2:Q+1,:,2);	
	end function projC

!! poisson 
	function poisson(f) result(p)
	implicit none 
		double precision, dimension(Q+1,N+1) :: f, p, denom, fhat, uhat
		double precision, dimension(Q+1) :: dn, depn
		double precision, dimension(N+1) :: dm, depm
		
		integer :: i
		
		do i = 1,Q+1
			dn(i) = i-1
		end do 
		depn = 2*dcos(pi*dn/(1.*(Q+1))) - 2
		depn = depn*(Q+1)**2
		
		do i = 1,N+1
			dm(i) = i-1
		end do
		depm = 2*dcos(pi*dm/(1.*(N+1))) - 2
		depm = depm*(N+1)**2
		
		do i = 1,Q+1 ! on remplit les lignes
			denom(i,:) = depm 
		end do 
		do i = 1,N+1 ! on remplit les colonnes
			denom(:,i) = denom(:,i) + depn
		end do
		
		where (denom .EQ. 0) denom = 1.
		
		fhat = dct2(f,Q+1,N+1)
		uhat = -fhat/denom
		p    = idct2(uhat,Q+1,N+1)	
	end function poisson

		function dct2(f,S1,S2) result(df)
		implicit none
		integer :: S1, S2
		double precision, dimension(S1,S2) :: f, df
		double precision, dimension(S1,S1) :: ADCT
		double precision, dimension(S2,S2) :: ADCT2
		double precision, dimension(S1) :: a1
		double precision, dimension(S2) :: a2
		integer :: u,x,v,y
			
		a1 = dsqrt(2d0/(1.*S1)); a1(1) = 1./dsqrt(1d0*S1)
		a2 = dsqrt(2d0/(1.*S2)); a2(1) = 1./dsqrt(1d0*S2)
		do u = 1,S1
			do x = 1,S1
				ADCT(u,x) = a1(u)*dcos(pi*(2*x-1)*(u-1)/(2.*S1))
			end do 
		end do 
		do v = 1,S2
			do y = 1,S2
				ADCT2(v,y) = a2(v)*dcos(pi*(2*y-1)*(v-1)/(2.*S2))
			end do 
		end do 
		
		df = matmul(ADCT,matmul(f,transpose(ADCT2)))
	end function dct2
	
	function idct2(df,S1,S2) result(f)
	implicit none
		integer :: S1, S2
		double precision, dimension(S1,S2) :: f, df
		double precision, dimension(S1,S1) :: ADCT
		double precision, dimension(S2,S2) :: ADCT2
		double precision, dimension(S1) :: a1
		double precision, dimension(S2) :: a2
		integer :: u,x,v,y
			
		a1 = dsqrt(2d0/(1.*S1)); a1(1) = 1./dsqrt(1d0*S1)
		a2 = dsqrt(2d0/(1.*S2)); a2(1) = 1./dsqrt(1d0*S2)
		do u = 1,S1
			do x = 1,S1
				ADCT(u,x) = a1(u)*dcos(pi*(2*x-1)*(u-1)/(2.*S1))
			end do 
		end do 
		do v = 1,S2
			do y = 1,S2
				ADCT2(v,y) = a2(v)*dcos(pi*(2*y-1)*(v-1)/(2.*S2))
			end do 
		end do 
		
		f = matmul(transpose(ADCT),matmul(df,ADCT2))
	end function idct2
end program transport

