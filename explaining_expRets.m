% set up parameters
nYears = 100;
blockSize = 250;
rho = 0.1;
muX = 0.08;
sigmaX = 0.17;
sigmaY = 0.01;

W = rand(nYears, 1);
U = zeros(nYears, 1);
U(1) = W(1);

for ii=2:nYears
    U(ii) = hinvGa(rho, W(ii), U(ii-1));
end

yearlyX = norminv(U, muX, sigmaX);

%% create daily y
dailyX = repmat((yearlyX./blockSize)', blockSize, 1);
dailyX = dailyX(:);

dailyY = dailyX + sigmaY * randn(nYears*blockSize, 1);
plot(dailyY(1:1000))

%% conduct regressions

% daily returns
[coeffDaily, bint, r, rint, stats] = regress(dailyY, [ones(nYears*blockSize, 1) dailyX]);
Rdaily = stats(1)

% yearly returns
yearlyY = zeros(nYears, 1);
for ii=1:nYears
    yearlyY(ii) = sum(dailyY(((ii-1)*blockSize+1):ii*blockSize));
end

[coeffYearly, bint, r, rint, stats] = regress(yearlyY, [ones(nYears, 1) yearlyX]);
Ryearly = stats(1)

%% plots
plot(yearlyX, yearlyY, '.')

plot(ranks(yearlyX), ranks(yearlyY),'.')

%%
nSS = 1000;
plot(1:nSS, dailyX(1:nSS), 'b.')
hold on;
plot(1:nSS, dailyY(1:nSS), 'r.')

figure(2)
plot(1:length(yearlyY), yearlyX, '.b')
hold on;
plot(1:length(yearlyY), yearlyY, '.r')

figure(3)
indx = randperm(nYears*blockSize, nSS);
dailyRanksX = ranks(dailyX);
dailyRanksY = ranks(dailyY);
plot(dailyRanksX(indx), dailyRanksY(indx), '.')