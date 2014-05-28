function vals = hinvGa(rho,U1,U2)
        % GAHINV - evaluate inverse gaussian h-function
        params = rho;
        vals = normcdf(norminv(U1).*sqrt(1-params.^2)...
            +params.*norminv(U2));
end