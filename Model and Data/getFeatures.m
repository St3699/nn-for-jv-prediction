function varargout = getFeatures(processed_lhs_filename, varargin)
    % Open the file
    fid = fopen(processed_lhs_filename, 'r');
    
    if fid == -1
        error('Failed to open the file.');
    end

    % Initialize variables to empty
    data = cell(1, length(varargin));  % Cell array to store data for each requested output variable

    % Read the file line by line
    while ~feof(fid)
        line = strsplit(fgetl(fid), ','); % Read the current line
        
        % Loop through each input argument (index) and store the corresponding column
        for i = 1:length(varargin)
            data{i}(end+1) = str2double(line{varargin{i}});
        end
    end 

    fclose(fid); 

    % Assign output variables dynamically
    for i = 1:length(data)
        varargout{i} = data{i};  % Return the data for each requested output variable
    end
end
