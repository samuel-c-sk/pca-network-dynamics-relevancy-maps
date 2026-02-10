function [A,finale_points, min_diff0, min_diff1, min_diff2, min_diff3] = projekt_function(points, tau, epsilon, K1, K2, diff0, diff1, diff2, diff3, stopG)

    len = size(points,1);   % 3712
    delta = 0.003;

    A = zeros(len);

    % helper: g(dx,dy)
    gfun = @(dx,dy) 1 / (1 + K1*dx^2 + K2*dy^2);

    % klastre indexy
    c0 = 1:22;
    c1 = 23:50;
    c2 = 51:81;
    c3 = 82:112;

    % init minimalne g vo vnutri klastrov
    min_diff0 = 1; min_diff1 = 1; min_diff2 = 1; min_diff3 = 1;

    % =============== TRAINED POINTS BLOCKS ===============

    % cluster 0
    if diff0 < stopG
        A = fill_cluster_block(A, points, c0, [c1 c2 c3], tau, epsilon, gfun, 0);
        min_diff0 = min_in_cluster(points, c0, gfun);
    else
        A(c0,c0) = eye(numel(c0)); % freeze
    end

    % cluster 1
    if diff1 < stopG
        A = fill_cluster_block(A, points, c1, [c0 c2 c3], tau, epsilon, gfun, 0);
        min_diff1 = min_in_cluster(points, c1, gfun);
    else
        A(c1,c1) = eye(numel(c1));
    end

    % cluster 2
    if diff2 < stopG
        A = fill_cluster_block(A, points, c2, [c0 c1 c3], tau, epsilon, gfun, 0);
        min_diff2 = min_in_cluster(points, c2, gfun);
    else
        A(c2,c2) = eye(numel(c2));
    end

    % cluster 3
    if diff3 < stopG
        A = fill_cluster_block(A, points, c3, [c0 c1 c2], tau, epsilon, gfun, 0);
        min_diff3 = min_in_cluster(points, c3, gfun);
    else
        A(c3,c3) = eye(numel(c3));
    end

    % =============== NEW POINTS (113..end) ===============
    for i = 113:len
        % napojenie na trained body 1..112
        sumg = 0;

        for j = 1:112
            dx = abs(points(j,1) - points(i,1));
            dy = abs(points(j,2) - points(i,2));
            g = gfun(dx,dy);
            if g < delta
                g = 0;
            end
            A(i,j) = -tau * g;
            sumg = sumg + g;
        end

        A(i,i) = 1 + tau * sumg;  % diagonala
    end

    % solve for new positions
    finale_points = A \ points;
end


function A = fill_cluster_block(A, points, inIdx, outIdx, tau, epsilon, gfun, dummy)
    %#ok<INUSD>
    % inIdx: body vnutri klastru
    % outIdx: trained body mimo klastru

    for ii = 1:numel(inIdx)
        i = inIdx(ii);

        % mimo klastru: backward diffusion (epsilon)
        for jj = 1:numel(outIdx)
            j = outIdx(jj);
            dx = abs(points(j,1) - points(i,1));
            dy = abs(points(j,2) - points(i,2));
            g = gfun(dx,dy);
            A(i,j) = -tau * epsilon * g;
        end

        % vnutri klastru: normal diffusion
        sum_in = 0;
        sum_out = 0;

        for jj = 1:numel(inIdx)
            j = inIdx(jj);
            if i ~= j
                dx = abs(points(j,1) - points(i,1));
                dy = abs(points(j,2) - points(i,2));
                g = gfun(dx,dy);
                A(i,j) = -tau * g;
                sum_in = sum_in + g;
            end
        end

        for jj = 1:numel(outIdx)
            j = outIdx(jj);
            dx = abs(points(j,1) - points(i,1));
            dy = abs(points(j,2) - points(i,2));
            g = gfun(dx,dy);
            sum_out = sum_out + g;
        end

        A(i,i) = 1 + tau * (sum_in + epsilon * sum_out);
    end
end


function mg = min_in_cluster(points, idx, gfun)
    mg = 1;
    for a = 1:numel(idx)
        for b = 1:numel(idx)
            if a ~= b
                i = idx(a); j = idx(b);
                dx = abs(points(j,1) - points(i,1));
                dy = abs(points(j,2) - points(i,2));
                g = gfun(dx,dy);
                if g < mg
                    mg = g;
                end
            end
        end
    end
end