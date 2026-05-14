function compile_windows()
% Build script for MyM (32-bit and 64-bit Windows)
%
% Note: the last 32-bit release of Matlab on Windows was R2015b

assert(strncmp(computer('arch'),'win',3),'Platform does not appear to be Windows.');

mym_base = fileparts(fileparts(mfilename('fullpath')));
mym_src = fullfile(mym_base, 'src');
build_out = fullfile(mym_base, 'build', mexext());
distrib_out = fullfile(mym_base, 'distribution', mexext());

% Set up input and output directories
mysql_base = fullfile(mym_base, 'mysqlclient'); 
if strfind(mexext(),'w32') %#ok<STRIFCND>
    % 32-bit... use mysql connector from MySQL 6.1.1
    mysql_base = fullfile(mym_base, 'mysql-connector');
end
mysql_include = fullfile(mysql_base, 'include');
mysql_lib = fullfile(mysql_base, ['lib_' mexext()]);

inc = {mysql_include};
lib = {mysql_lib};

platform_include = fullfile(mysql_base, ['include_' mexext()]);
if exist(platform_include,'dir')
    inc = cat(2,inc,platform_include);
end

mariadb_lib = fullfile(mym_base, 'maria-plugin' ,['lib_',mexext()]);
if exist(mariadb_lib,'dir')
    lib = cat(2,lib,mariadb_lib);
end

zlib_include = fullfile(mym_base, 'zlib', ['include_' mexext()]);
if exist(zlib_include,'dir')
    inc = cat(2,inc,zlib_include);
end

zlib_lib = fullfile(mym_base, 'lib', mexext());
if exist(zlib_lib,'dir')
    lib = cat(2,lib,zlib_lib);
end

inc = cellfun(@(x) sprintf('-I"%s"',x),inc,'UniformOutput',false);
lib = cellfun(@(x) sprintf('-L"%s"',x),lib,'UniformOutput',false);

mkdir(build_out);
mkdir(distrib_out);
oldp = cd(build_out);
pwd_reset = onCleanup(@() cd(oldp));

mex( ...
    '-v', ...
    '-largeArrayDims', ...
    inc{:}, lib{:}, ...
    '-llibmysql', ...
    '-lmysqlclient', ...
    '-lzlib', ...
    fullfile(mym_src, 'mym.cpp'));

% Pack mex with all dependencies into distribution directory
copyfile(['mym.' mexext()], distrib_out);
copyfile(fullfile(mym_src, 'mym.m'), distrib_out);
copyfile(fullfile(mysql_lib, '*.dll'), distrib_out);
if exist(mariadb_lib,'dir')
    copyfile(fullfile(mariadb_lib, 'dialog.dll'), distrib_out);
end
