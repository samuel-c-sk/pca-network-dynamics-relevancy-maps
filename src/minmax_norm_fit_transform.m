function [Xn, mm] = minmax_norm_fit_transform(X)
% X: NxD
% mm: 2xD (min; max)
    [N,D] = size(X);
    mm = zeros(2,D);
    Xn = zeros(size(X));

    for d = 1:D
        mn = min(X(:,d));
        mx = max(X(:,d));
        mm(1,d) = mn;
        mm(2,d) = mx;

        denom = mx - mn;
        if denom == 0
            Xn(:,d) = zeros(N,1);
        else
            Xn(:,d) = (X(:,d) - mn) / denom;
        end
    end
end