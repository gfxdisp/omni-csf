% Plot spatio-chromatic CSF as a function of frequency for several
% luminance levels

sccsf = SCCSF_ConeContrastMat(); % The class with the spatio-chromatic CSF model

xyz_gray = [0.9505    1.0000    1.0888]; % D65
lms_gray = xyz2lms2006( xyz_gray );

LUMs = 10.^(-2:4);
freq = logspace( log10(0.25), log10(64) )'; % Must be a column vector
area = pi;

dir_labels = { 'L+M', 'L-M', 'S-(L+M)' };
clf
for cc=1:3 % For three colour directions in the DKL space
    
    subplot( 1, 3, cc );
    
    hh = [];
    for kk=1:length(LUMs) % For each luminance level
        
        LMS_mean = lms_gray*LUMs(kk);
        
        DKL_deltas = eye(3); % Colour directions in the DKL space
        LMS_delta = dkl2lms_d65( DKL_deltas(cc,:) );
        
        % Note that "sensitivity" method works only with column vectors and
        % scalars.
        S = sccsf.sensitivity( freq, LMS_mean, LMS_delta, area );
        
        hh(kk) = plot( freq, S, 'DisplayName', sprintf( '%gcd/m^2', LUMs(kk) ) );
        hold on
        
    end
    
    hold off
    
    set( gca, 'XScale', 'log' );
    xlabel( 'Frequency [cpd]' );
    xlim( [freq(1) freq(end)] );
    
    set( gca, 'YScale', 'log' );
    ylabel( 'Sensitivity [1/cone contrast]' );
    ylim( [1 500] );
    
    if cc==1
        legend( hh, 'Location', 'Best' );
    end
    
    title( sprintf( '%s (%g deg^2)', dir_labels{cc}, area ) );
    
end
