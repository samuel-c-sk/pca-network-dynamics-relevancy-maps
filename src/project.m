clear; clc; close all;

outDir = fullfile(pwd, "results");
if ~exist(outDir, "dir")
    mkdir(outDir);
end

%% ---------- 1) Load trained points (112x72) ----------
data = readmatrix('112x72.csv', 'Delimiter', ',');

% drop columns that are all NaN (typicky extra stĺpec z koncovej čiarky)
data(:, all(isnan(data), 1)) = [];

[numRows, numCols] = size(data);
assert(numRows == 112, "112x72.csv: ocakavam 112 riadkov.");
assert(numCols == 72,  "112x72.csv: ocakavam 72 stlpcov po odfiltrovani NaN.");

% min-max normalize (store mins/maxs)
[normalizedData, beforePCA] = minmax_norm_fit_transform(data);

% PCA (store coeff + mu + score)
[coeff, score, ~, ~, ~, mu] = pca(normalizedData);

% min-max normalize PCA coordinates (store mins/maxs)
[normalizedDataAfterPCA, afterPCA] = minmax_norm_fit_transform(score);

%% ---------- Visual check (trained points) ----------
E0  = 1:22;
F0  = (E0(end)+1):(E0(end)+28);
G0  = (F0(end)+1):(F0(end)+31);
B10 = (G0(end)+1):(G0(end)+31);

figure; hold on;
scatter3(normalizedDataAfterPCA(E0,1), normalizedDataAfterPCA(E0,2), normalizedDataAfterPCA(E0,3), 20, "filled");
scatter3(normalizedDataAfterPCA(F0,1), normalizedDataAfterPCA(F0,2), normalizedDataAfterPCA(F0,3), 20, "filled");
scatter3(normalizedDataAfterPCA(G0,1), normalizedDataAfterPCA(G0,2), normalizedDataAfterPCA(G0,3), 20, "filled");
scatter3(normalizedDataAfterPCA(B10,1),normalizedDataAfterPCA(B10,2),normalizedDataAfterPCA(B10,3),20, "filled");
title('Trained points after PCA + norm');
grid on; hold off;
exportgraphics(gcf, fullfile(outDir, "trained_points_pca_norm.png"), "Resolution", 300);

%% ---------- 2) Load new observations (3600x72) - OLD STYLE (ako si mal) ----------
fileName2 = 'statForRelevancyMap60x60.csv';
dataNew = readmatrix(fileName2, 'Delimiter', ',');
dataNew(:, all(isnan(dataNew), 1)) = [];  % pre istotu

[numRowsNew, numColsNew] = size(dataNew);
assert(numRowsNew == 3600, "Ocakavam 3600 riadkov (60x60).");
assert(numColsNew == 72,   "Ocakavam 72 stlpcov.");

% --- 1) normovanie pomocou beforePCA ---
normalizedDataNew = zeros(size(dataNew));
for col = 1:numColsNew
    diff = beforePCA(2,col) - beforePCA(1,col);
    if diff == 0
        normalizedDataNew(:,col) = zeros(numRowsNew,1);
    else
        normalizedDataNew(:,col) = (dataNew(:,col) - beforePCA(1,col)) / diff;
    end
end

% --- 2) centrovanie (tak ako si mal pôvodne) ---
centDataNew = zeros(size(normalizedDataNew));
for col = 1:numColsNew
    centDataNew(:,col) = normalizedDataNew(:,col) - mean(normalizedDataNew(:,col));
end

% --- 3) PCA transformácia cez coeff ---
centDataNewPCA = centDataNew * coeff;

% --- 4) normovanie pomocou afterPCA ---
normalizedDataNewPCA = zeros(size(centDataNewPCA));
for col = 1:numColsNew
    diff = afterPCA(2,col) - afterPCA(1,col);
    if diff == 0
        normalizedDataNewPCA(:,col) = zeros(numRowsNew,1);
    else
        normalizedDataNewPCA(:,col) = (centDataNewPCA(:,col) - afterPCA(1,col)) / diff;
    end
end

%% ---------- Visual check (trained + new) ----------
figure; hold on;
scatter3(normalizedDataAfterPCA(E0,1), normalizedDataAfterPCA(E0,2), normalizedDataAfterPCA(E0,3), 20, "filled");
scatter3(normalizedDataAfterPCA(F0,1), normalizedDataAfterPCA(F0,2), normalizedDataAfterPCA(F0,3), 20, "filled");
scatter3(normalizedDataAfterPCA(G0,1), normalizedDataAfterPCA(G0,2), normalizedDataAfterPCA(G0,3), 20, "filled");
scatter3(normalizedDataAfterPCA(B10,1),normalizedDataAfterPCA(B10,2),normalizedDataAfterPCA(B10,3),20, "filled");
scatter3(normalizedDataNewPCA(:,1), normalizedDataNewPCA(:,2), normalizedDataNewPCA(:,3), 8, "filled");
title('Trained + New points after PCA + norm');
grid on; hold off;

exportgraphics(gcf, fullfile(outDir, "trained_plus_new_pca_norm.png"), "Resolution", 300);
%% ---------- 3) Dynamics parameters ----------
tau = 1;
epsilon = -0.01;   % alebo 0.01 ak by si g násobil -epsilon
K1 = 3100;
K2 = 1500;

% stop threshold
stopG = 0.995;
maxIter = 200;

points = [normalizedDataAfterPCA; normalizedDataNewPCA];

diff0 = 0; diff1 = 0; diff2 = 0; diff3 = 0;

figure; hold on;

videoPath = fullfile(outDir, "dynamics_iterations.mp4");
v = VideoWriter(videoPath, "MPEG-4");
v.FrameRate = 2;    
open(v);

iter = 0;
while (diff0 < stopG || diff1 < stopG || diff2 < stopG || diff3 < stopG) && iter < maxIter
    iter = iter + 1;

    [A, pointsNext, diff0, diff1, diff2, diff3] = projekt_function(points, tau, epsilon, K1, K2, diff0, diff1, diff2, diff3, stopG);

    points = pointsNext;

    cla;
    scatter(points(113:end,1), points(113:end,2), 10, "filled");  % new
    scatter(points(1:22,1),   points(1:22,2),   25, "filled");
    scatter(points(23:50,1),  points(23:50,2),  25, "filled");
    scatter(points(51:81,1),  points(51:81,2),  25, "filled");
    scatter(points(82:112,1), points(82:112,2), 25, "filled");

    title(sprintf("Iter %d | minG: [%.4f %.4f %.4f %.4f]", iter, diff0, diff1, diff2, diff3));
    drawnow;
    frame = getframe(gcf);
    writeVideo(v, frame);
end

hold off;
close(v);

%% ---------- 4) Relevancy maps ----------
lambda = 12;
[M0,M1,M2,M3] = relevancy_map(points, lambda);

% vizualizacia
figure; imshow(imresize(M0, 5, 'nearest'), []); colormap gray; title('Map cluster 0');
exportgraphics(gcf, fullfile(outDir, "relevancy_map_cluster0.png"), "Resolution", 300);
figure; imshow(imresize(M1, 5, 'nearest'), []); colormap gray; title('Map cluster 1');
exportgraphics(gcf, fullfile(outDir, "relevancy_map_cluster1.png"), "Resolution", 300);
figure; imshow(imresize(M2, 5, 'nearest'), []); colormap gray; title('Map cluster 2');
exportgraphics(gcf, fullfile(outDir, "relevancy_map_cluster2.png"), "Resolution", 300);
figure; imshow(imresize(M3, 5, 'nearest'), []); colormap gray; title('Map cluster 3');
exportgraphics(gcf, fullfile(outDir, "relevancy_map_cluster3.png"), "Resolution", 300);