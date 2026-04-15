function MAC = computeMAC(complexModes)

    Nm = size(complexModes,2);
    MAC = zeros(Nm,Nm);

    for i = 1:Nm
        for j = 1:Nm
            phi_i = complexModes(:,i);
            phi_j = complexModes(:,j);

            MAC(i,j) = abs(phi_i' * phi_j)^2 / ...
                       ((phi_i' * phi_i) * (phi_j' * phi_j));
        end
    end
end