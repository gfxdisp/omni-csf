classdef SCCSF_ConeContrastMat < SCCSF
    %SCCSF_ConeContrastMat 
    % Spatio-chromatic contrast sensitivity function for any colour
    % direction. 
    %
    % The latest version of the code can be found at: https://github.com/gfxdisp/omni-csf
    %
    % The model is described in the paper:
    %
    % Rafał K. Mantiuk, Minjung Kim, Maliha Ashraf, Qiang Xu, M. Ronnier Luo, Jasna Martinovic and Sophie Wuerger. 
    % "Practical color contrast sensitivity functions for luminance levels up to 10000 cd/m^2". 
    % In: Color Imaging Conference (CIC28), 2020 [PDF](https://www.cl.cam.ac.uk/~rkm38/pdfs/mantiuk2020practical_csf.pdf)

    
    properties( Constant )
        % which entries in the meachism matrix should be fixed to 1
        Mones = [ 1 0 0;
            1 0 0;
            0 0 1 ];
        
        beta = 2;
    end
    
    methods
        
        function obj = SCCSF_ConeContrastMat( fitted_par_vector_file )
            
            obj.par = obj.get_default_par();
            
            if exist( 'fitted_par_vector_file', 'var' )
                lv = load( fitted_par_vector_file );
                obj.par = obj.param2struct( obj.par, lv.fitted_par_vector );
            end
            
        end
        
        function name = short_name( obj )
            % A short name that could be used as a part of a file name
            name = 'cone-contrast-mat';
        end
        
        function M_lms2acc = get_lms2acc( obj )
            % Get the colour mechanism matrix
            
            M_lms2acc = ones(3,3);
            % Set only the cells in the array that should be ~= 1
            M_lms2acc(~SCCSF_ConeContrastMat.Mones(:)) = obj.par.colmat;
            % Get the right sign
            M_lms2acc =  M_lms2acc .* [ 1 1 1; 1 -1 1; -1 -1 1];
        end
        
        function [P, C] = pdet( obj, freq, LMS_mean, LMS_delta, area )
            % Predict the probility of detecting a Gabour patch of certain chromatic
            % direction and amplitide
            %
            % [P, C] = pdet( obj, freq, LMS_mean, LMS_delta, area )
            %
            % freq - spatial frequency in cpd
            % LMS_mean - LMS of the background colour (CIE2006 CMF)
            % LMS_delta - colour direction vector in the LMS space (LMS_peak-LMS_mean)
            % area - area in deg^2
            %
            % The method returns:
            % P - The probability of detection
            % C - Normalized detection contrast (1 when P=0.5)                        
            
            M_lms2acc = obj.get_lms2acc();
            
            lum = sum(LMS_mean(:,1:2),2);
            
            CC_LMS = LMS_delta ./ LMS_mean;
            
            CC_ACC = CC_LMS * M_lms2acc';
                        
            C_A = abs(CC_ACC(:,1));
            C_R = abs(CC_ACC(:,2));
            C_Y = abs(CC_ACC(:,3));
            
            C_A_n = C_A.*obj.csf_freq_size_lum( freq, area, 1, lum );
            C_R_n = C_R.*obj.csf_freq_size_lum( freq, area, 2, lum );
            C_Y_n = C_Y.*obj.csf_freq_size_lum( freq, area, 3, lum );
            
            C = (C_A_n.^obj.beta + C_R_n.^obj.beta + C_Y_n.^obj.beta).^(1/obj.beta);
            
            P = 1 - exp( log(0.5)*C );
            
        end
        
        function [S, LMS_delta_thr, P, C] = sensitivity( obj, freq, LMS_mean, LMS_delta, area )
            % Predict the sensitivity for a detection of a Gabour patch of certain chromatic
            % direction and amplitide. The difference between this method
            % and pdet() is that it predicts where the threshold is
            % (LMS_delta_thr) while pdet() onlt tells what is the
            % probability of detection for a given LMS_delta.
            %
            % [P, C, S, LMS_delta_thr] = camliv_colour_difference( freq, LMS_mean, LMS_delta, area, params )
            %
            % freq - spatial frequency in cpd
            % LMS_mean - LMS of the background colour (CIE2006 CMF)
            % LMS_delta - colour direction vector in the LMS space (LMS_peak-LMS_mean)
            % area - area in deg^2
            %
            % The method returns:
            % S - Sensitivity (the inverse of cone contrast at the threshold)
            % LMS_delta_thr - vector of the same direction as LMS_delta, but with the
            %     length adjusted so that it points to the detection threshold
            % P - The probability of detection
            % C - Normalized detection contrast (1 when P=0.5)
            
            [P, C] = obj.pdet( freq, LMS_mean, LMS_delta, area );
            
            
            %            LMS_delta_thr = repmat((C.^(-1/beta)), [1 3]) .* LMS_delta;
            LMS_delta_thr = repmat((C.^(-1)), [1 3]) .* LMS_delta;
            
            S = 1./ (sqrt(sum((LMS_delta_thr ./ LMS_mean).^2, 2))/sqrt(3));
            
        end
        
        function print( obj, fh )
            % Print the model parameters in a format ready to be pasted into
            % get_default_par()
            
            for cc=1:3
                fn = fieldnames( obj.par.cm(cc) );
                for ff=1:length(fn)
                    fprintf( fh, '\tp.cm(%d).%s = ', cc, fn{ff} );
                    obj.print_vector( fh, obj.par.cm(cc).(fn{ff}) );
                    fprintf( fh, ';\n' );
                end
                fprintf( 1, '\n' )
            end
            
            fn = fieldnames( obj.par );
            for ff=1:length(fn)
                if ismember( fn{ff}, { 'cm', 'ds' } )
                    continue;
                end
                fprintf( fh, '\tp.%s = ', fn{ff} );
                obj.print_vector( fh, obj.par.(fn{ff}) );
                fprintf( fh, ';\n' );
            end
            
            M_lms2acc = obj.get_lms2acc();
            
            fprintf( fh, evalc( 'M_lms2acc' ) );
            
        end
        
        
        function S = csf_freq_size_lum( obj, freq, area, color_dir, lum )
            % Internal. Do not call from outside the object.
            % A nested CSF as a function of luminance
            
            N = max( [length(freq) length(area) length(color_dir) length(lum)] );
            
            assert( length(freq)==1 || all( size(freq)==[N 1] ) );
            assert( length(area)==1 || all( size(area)==[N 1] ) );
            assert( length(color_dir)==1 || all( size(color_dir)==[N 1] ) );
            assert( length(lum)==1 || all( size(lum)==[N 1] ) );
            
            % Support for a GPU
            if isa( freq, 'gpuArray' ) || isa( area, 'gpuArray' ) || isa( color_dir, 'gpuArray' ) || isa( lum, 'gpuArray' )
                cl = 'gpuArray';
            else
                cl = class(freq);
            end
            
            Nl = length(lum);
            S_max = zeros(Nl,1, cl);
            f_max = zeros(Nl,1, cl);
            bw = zeros(Nl,1, cl);
            gamma = zeros(Nl,1, cl);
            %eta = zeros(Nl,1);
            
            if length(color_dir)==1 && Nl>1
                color_dir = ones(Nl,1, cl)*color_dir;
            end
            
            for cc=1:3
                ss = (color_dir == cc);
                S_max(ss) = obj.get_lum_dep( obj.par.cm(cc).S_max, lum(ss) );
                f_max(ss) = obj.get_lum_dep( obj.par.cm(cc).f_max, lum(ss) );
                bw(ss) = obj.get_lum_dep( obj.par.cm(cc).bw, lum(ss) );
                gamma(ss) = obj.get_lum_dep( obj.par.cm(cc).gamma, lum(ss) );
                %    eta(ss) = obj.get_lum_dep( p.cm(cc).eta, lum(ss) );
            end
            
            S = obj.csf_freq_size( freq, area, color_dir, S_max, f_max, bw, gamma );
            
        end
        
        function S = csf_freq_size( obj, freq, area, color_dir, S_max, f_max, bw, gamma )
            % log-parabola + Rovamo's stimulus size model
            
            % The stimulus size model from the paper:
            %
            % Rovamo, J., Luntinen, O., & N�s�nen, R. (1993).
            % Modelling the dependence of contrast sensitivity on grating area and spatial frequency.
            % Vision Research, 33(18), 2773�2788.
            %
            % Equation on the page 2784, one after (25)
            
            S_peak = S_max ./ 10.^( (log10(freq) - log10(f_max)).^2./(0.5*2.^bw) );
            
            % low-pass for chromatic channels
            ss = (freq<f_max) & (color_dir>1);
            if length(S_max)>1
                S_peak(ss) = S_max(ss);
            else
                S_peak(ss) = S_max;
            end
            
            %Ac_prime_tab = [114 40 40];
            
            %Ac_prime = 114; %TODO: Ac_prime_tab(color_dir);
            
            Ac_prime = zeros(length(color_dir),1);
            for cc=1:3
                ss = (color_dir == cc);
                Ac_prime(ss) = obj.par.cm(cc).Ac_prime;
            end
            
            f0 = 0.65;
            
            k = Ac_prime + area.*f0;
            
            %S = S_peak .* sqrt( area.*freq.^gamma ./ (k + area.*freq.^gamma) );
            S = S_peak .* sqrt( area.^gamma.*freq.^2 ./ (k + area.^gamma.*freq.^2) );
            %S = S_peak .* sqrt( area.^gamma.*freq.^eta ./ (k + area.^gamma.*freq.^eta) );
            
        end               
        
    end   
    
    methods( Static )
        
        function p = get_default_par()
            
            p = SCCSF.get_dataset_par();
            
            % Fitted on 08/10/2020  - excluding the older observer data
            
            p.cm(1).S_max = [ 361635 5.42519 0.320472 758334 7.89951e-05 ];
            p.cm(1).f_max = [ 2.25325 1880.51 0.190874 ];
            p.cm(1).bw = 1.04781;
            p.cm(1).gamma = 1.09774;
            p.cm(1).Ac_prime = 45.0225;

            p.cm(2).S_max = [ 468.431 12.2482 0.522667 ];
            p.cm(2).f_max = 0.10048;
            p.cm(2).bw = 2.82971;
            p.cm(2).gamma = 1.70328;
            p.cm(2).Ac_prime = 1.06655;

            p.cm(3).S_max = [ 12799.1 160.831 0.358707 ];
            p.cm(3).f_max = 1.03772e-07;
            p.cm(3).bw = 5.28354;
            p.cm(3).gamma = 1.44676;
            p.cm(3).Ac_prime = 0.389358;

            p.colmat = [ 0.00123883 0.229778 0.932581 1.07013 6.41585e-07 0.0037047 ];
                
            p.ds.xuqiang = 1.78108;
            p.ds.sw = 1.38261;
            p.ds.kim2013_ach = 2.74226;
            p.ds.kim2013_ch = 0.706694;
            p.ds.four_centres = 1.11533;
            
        end
        
    end
end

