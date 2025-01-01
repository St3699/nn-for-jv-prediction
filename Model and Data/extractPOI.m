function [V, J, Voc, Joc, Vsc, Jsc, Vmpp, Jmpp, FF, Rseries, Rshunt] = extractPOI(V, J)

% Calculate open circuit voltage
[J_unique, idx_unique] = unique(J);
V_unique = V(idx_unique);
Voc = interp1(J_unique, V_unique, 0, 'pchip', 'extrap'); 
Joc = 0;
V = sort([V, Voc]);
J = sort([J, Joc], "descend");

% Calculate short circuit current
% [~, idx_jsc] = min(abs(V));
[~, idx_jsc] = find(V == 0, 1, 'first');
Jsc = J(idx_jsc);
Vsc = V(idx_jsc);

% Calculate maximum power point
V_fine = linspace(min(V), max(V), 200);  % Create a fine voltage grid
J_fine = interp1(V, J, V_fine, 'pchip');
P = V_fine .* J_fine; 
dP_dV = gradient(P, V_fine);
% Find where dP/dV crosses zero
z = find(diff(sign(dP_dV)) ~= 0, 1, 'first');
Vmpp = interp1(dP_dV(z:z+1), V_fine(z:z+1), 0, 'linear');
Jmpp = interp1(V, J, Vmpp, 'pchip');  % Interpolate J at Vmpp
V = sort([V, Vmpp]);
J = sort([J, Jmpp], "descend");

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
FF = (Vmpp * Jmpp) / (Voc * Jsc);

% Calculate Shunt Resistance
dV_dJ = gradient(V, J);  % Derivative of Voltage with respect to Current
Rshunt = -dV_dJ(idx_jsc);  % Evaluate the derivative at J = Jsc
if abs(Rshunt) == Inf
    [J_y2, idx_y2] = find(J < Jsc, 1, 'first');
    V_y2 = V(idx_y2);
    Rshunt = -(0-V_y2)/(Jsc-J_y2);
end

% Calculate Series Resistance
A = (Vmpp - (Jsc - Jmpp)*Rshunt)*log10((Vmpp - (Jsc - Jmpp)*Rshunt)/(Voc - Jsc*Rshunt));
B = Vmpp - Jmpp*Rshunt;
Rseries = ((A-B)/(A+B))*(Vmpp/Jmpp) + (B/(A+B))*(Voc/Jmpp);

end