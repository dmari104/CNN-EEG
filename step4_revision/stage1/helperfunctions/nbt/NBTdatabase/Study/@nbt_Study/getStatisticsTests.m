

%------------------------------------------------------------------------------------
% Originally created by Simon-Shlomo Poil (2014), see NBT website (http://www.nbtwiki.net) for current email address
%------------------------------------------------------------------------------------
%
% ChangeLog - see version control log at NBT website for details.
%
% Copyright (C) <year>  <Main Author>  (Neuronal Oscillations and Cognition group,
% Department of Integrative Neurophysiology, Center for Neurogenomics and Cognitive Research,
% Neuroscience Campus Amsterdam, VU University Amsterdam)
%
% Part of the Neurophysiological Biomarker Toolbox (NBT)
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
%
% See Readme.txt for additional copyright information.
% -------------------------------------------------------------------------
function  S = getStatisticsTests(index)
%if index == 0 we return a list of all available tests.
if(index ==0)
    S = {...
        'Grand average PSD', ...
        'Grand average DFA', ...
        'Grand median plot', ...
        'Grand mean plot', ...
        'Median group plot', ...
        'Mean group plot',...
        'Normality (Univariate): Lilliefors test', ...
        'Normality (Univariate): Shapiro-Wilk test', ...
        'Parametric (Univariate): Student paired t-test', ...
        'Non-Parametric (Univariate): Wilcoxon signed rank test', ...
        'Parametric (Bi-variate): Student unpaired t-test', ...
        'Non-Parametric (Bi-variate): Wilcoxon rank sum test', ...
        'Non-Parametric (Bi-variate): Permutation for mean difference', ...
        'Non-Parametric (Univariate): Permutation for paired mean difference', ...
        'Non-Parametric (Bi-variate): Permutation for median difference', ...
        'Non-Parametric (Univariate): Permutation for paired median difference', ...
        'Non-Parametric (Bi-variate): Permutation for correlation', ...
        'One-way ANOVA', ...
        'Two-way ANOVA', ...
        'n-way ANOVA', ...
        'Kruskal-Wallis test', ...
        'Friedman test', ...
        'Spider plot', ...
        'Elastic logit', ...
        'LS-SVM', ...
        'Regression', ...
        'Validate classification', ...
        'Compare biomarkers' ...
        'Biomarker curve' ...
        'Biomarker scatter plot' ...
        };
    return
end
%Otherwise we return the specific statistics object
switch index
    case 1 %Grand average PSD
        S = nbt_GrandAveragePSD;
    case 2
        S = nbt_GrandAverageDFA;
    case 3 %'Grand median plot'; 
    case 4 %'Grand mean plot';
    case 5 %'Median group plot';
    case 6 %'Mean group plot';
    case 7 % Normality (Univariate): Lilliefors test
        S = nbt_lilliefors;
    case 8 % Normality (Univariate): Shapiro-Wilk test
    case 9 % Parametric (Univariate): Student paired t-test
        S = nbt_ttest;
    case 10 % Non-Parametric (Univariate): Wilcoxon signed rank test
        S = nbt_signrank;
    case 11 % Parametric (Bi-variate): Student unpaired t-test
        S = nbt_ttest2;
    case 12 % Non-Parametric (Bi-variate):  Wilcoxon rank sum test
        S = nbt_ranksum;
        %.statfuncname='Wilcoxon rank sum test';
    case 13 % Non-Parametric (Univariate):  Permutation for difference means or medians
        %        s.statfuncname='Permutation for mean difference';
    case 14 % Non-Parametric (Univariate):  Permutation for paired difference means or medians
        %s.statfuncname='Permutation for paired mean difference';
    case 15 % Non-Parametric (Univariate):  Permutation for difference means or medians
        %.statfuncname='Permutation for median difference';
    case 16 % Non-Parametric (Univariate):  Permutation for paired difference means or medians
        %s.statfuncname='Permutation for paired median difference';
    case 17 % Non-Parametric (Bi-variate):  Permutation for correlation
        % s.statfuncname='Permutation for correlation';
    case 18 % ANOVA one-way
        %.statfuncname = 'One-way ANOVA';
    case 19 % ANOVA two-way
        %s.statfuncname = 'Two-way ANOVA';
    case 20
        %s.statfuncname = 'n-way ANOVA';
    case 21 %Kruskal-Wallis test
        %s.statfuncname = 'Kruskal-Wallis test';
    case 22 %Friedman test
        %s.statfuncname = 'Friedman test';
    case 23 % Spider plot
        %s.statfuncname = 'Spider plot';
        S = nbt_spiderplot;
    case 24
        S = nbt_elasticLogit;
    case 25
        S = nbt_lssvm;
    case 26
        S = nbt_regression;
    case 27
        S = nbt_ValidateClassifier;
    case 28
        S = nbt_comparebiomarkers;
    case 29
        S = nbt_biomarkerCurve;
    case 30
        S = nbt_scatterPlot;
    otherwise
        S = [];
end
end