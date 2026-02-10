function [M0,M1,M2,M3] = relevancy_map(points, lambda)

    % 60x60 maps
    M0 = zeros(60,60);
    M1 = zeros(60,60);
    M2 = zeros(60,60);
    M3 = zeros(60,60);

    c0 = 1:22;
    c1 = 23:50;
    c2 = 51:81;
    c3 = 82:112;

    for i = 113:3712
        idx = i - 112; % 1..3600
        [r,c] = ind2sub([60,60], idx);

        p = points(i,1:2);

        [d0] = min_dist_to_cluster(points, c0, p);
        [d1] = min_dist_to_cluster(points, c1, p);
        [d2] = min_dist_to_cluster(points, c2, p);
        [d3] = min_dist_to_cluster(points, c3, p);

        % priradenie
        dmin = min([d0 d1 d2 d3]);

        if dmin >= 0.05
            rel = 0; % nezaradeny
        else
            rel = exp(-lambda * (dmin^2));
        end

        if dmin == d0 && d0 < 0.05
            M0(c,r) = rel;
        elseif dmin == d1 && d1 < 0.05
            M1(c,r) = rel;
        elseif dmin == d2 && d2 < 0.05
            M2(c,r) = rel;
        elseif dmin == d3 && d3 < 0.05
            M3(c,r) = rel;
        end
    end
end


function d = min_dist_to_cluster(points, clusterIdx, p)
    d = inf;
    for k = clusterIdx
        q = points(k,1:2);
        dk = sqrt((p(1)-q(1))^2 + (p(2)-q(2))^2);
        if dk < d
            d = dk;
        end
    end
end