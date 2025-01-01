function [V, I, Voc, Ioc, Vsc, Isc, Vmpp, Impp, FF, Rseries, Rshunt] = extractPOI(V, I)

% Calculate open circuit voltage
[I_unique, idx_unique] = unique(I);
V_unique = V(idx_unique);
Voc = interp1(I_unique, V_unique, 0, 'pchip', 'extrap'); 
Ioc = 0;
V = sort([V, Voc]);
I = sort([I, Ioc], "descend");

% Calculate short circuit current
% [~, idx_isc] = min(abs(V));
[~, idx_isc] = find(V == 0, 1, 'first');
Isc = I(idx_isc);
Vsc = V(idx_isc);

% Calculate maximum power point
V_fine = linspace(min(V), max(V), 200);  % Create a fine voltage grid
I_fine = interp1(V, I, V_fine, 'pchip');
P = V_fine .* I_fine; 
dP_dV = gradient(P, V_fine);
% Find where dP/dV crosses zero
z = find(diff(sign(dP_dV)) ~= 0, 1, 'first');
Vmpp = interp1(dP_dV(z:z+1), V_fine(z:z+1), 0, 'linear');
Impp = interp1(V, I, Vmpp, 'pchip');  % Interpolate I at Vmpp
V = sort([V, Vmpp]);
I = sort([I, Impp], "descend");

% % Plot the gradient
% figure;
% plot(V_fine, dP_dV);  % Plot the gradient curve
% hold on; plot(V_fine, P);
% plot(Vmpp, 0, 'ro', 'MarkerSize', 8, 'LineWidth', 2);  % Highlight the MPP (where gradient is zero)
% xlabel('Voltage (V)');
% ylabel('dP/dV');
% title('Gradient of Power with Respect to Voltage');
% grid on;
% legend('dP/dV', 'Maximum Power Point (MPP)');
% hold off;

% calculate fill factor
FF = (Vmpp * Impp) / (Voc * Isc);

% Calculate Shunt Resistance
dV_dI = gradient(V, I);  % Derivative of Voltage with respect to Current
Rshunt = -dV_dI(idx_isc);  % Evaluate the derivative at I = Isc
if abs(Rshunt) == Inf
    [I_y2, idx_y2] = find(I < Isc, 1, 'first');
    V_y2 = V(idx_y2);
    Rshunt = -(0-V_y2)/(Isc-I_y2);
end

% Calculate Series Resistance
A = (Vmpp - (Isc - Impp)*Rshunt)*log10((Vmpp - (Isc - Impp)*Rshunt)/(Voc - Isc*Rshunt));
B = Vmpp - Impp*Rshunt;
Rseries = ((A-B)/(A+B))*(Vmpp/Impp) + (B/(A+B))*(Voc/Impp);

end