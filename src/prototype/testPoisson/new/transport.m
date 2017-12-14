clc
clear all
close all 

globals;

%% New implementation without staggered grid %%
N = 50; 
Q = 49; 

X       = [0:N]/N;
[XX,YY] = meshgrid(X,[0:Q]/Q); YY = flipud(YY);

normalise = @(f) f/sum(f(:)); epsilon = 1e-10;
f0 = normalise(epsilon + gauss(0.3,0.05,N));
f1 = normalise(epsilon + gauss(0.8,0.05,N));% + gauss(0.7,0.05,N));
%f1 = normalise(epsilon + 1./(1+10000*(X-0.5).^2));

J = @(w) sum(sum(sum(w(:,:,1).^2./max(w(:,:,2),max(epsilon,1e-10))))); % cost 

alpha = 1.0; g = 2.0;

z  = zeros(Q+1,N+1,2);
w0 = zeros(Q+1,N+1,2); w1 = zeros(Q+1,N+1,2);
t  = [Q:-1:0]/Q;
tt = repmat(t',1,N+1);
w0 = (1-tt).*repmat(f0,Q+1,1) + tt.*repmat(f1,Q+1,1);

niter = 1000;
cout = zeros(1,niter);
minF = zeros(1,niter);
divV = zeros(1,niter);
tic
for l = 1:niter
    w1 = w0 + alpha*(proxJ(2*z-w0,g) - z);
    [z, divV(l)] = projC(w1);
    w0 = w1;
    if mod(l,20) == 0
        surf(XX,YY,z(:,:,2))
        title(['Iteration ',num2str(l)]);
        drawnow;
    end
    
    cout(l) = J(z);
    minF(l) = min(min(z(:,:,2)));
end
toc
clf

figure; 
surf(XX,YY,z(:,:,2));
title('Optimal transport');


figure; 
subplot(311)
plot([1:niter],cout);
title('cout');
subplot(312)
plot([1:niter],minF);
title('Minimum de F');
subplot(313);
plot([1:niter],divV);
title('divergence violation');
