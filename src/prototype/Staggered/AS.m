function U = AS(R)
    globals;
    U = zeros(Q+2,N+2,2);
    U(1:Q+2,1:N+2,:) = divAdj(R(1:Q+1,1:N+1));

    U(1:Q+1,1,1)     = U(1:Q+1,1,1) + R(1:Q+1,N+2);
    U(1:Q+1,N+2,1)   = U(1:Q+1,N+2,1) + R(1:Q+1,N+3);

    U(1,1:N+1,2)     = U(1,1:N+1,2) + R(Q+3,1:N+1);
    U(Q+2,1:N+1,2)   = U(Q+2,1:N+1,2) + R(Q+2,1:N+1);
end
