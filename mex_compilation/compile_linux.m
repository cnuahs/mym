function compile_linux()
% Build script for MyM (32-bit and 64-bit Linux)
%
% Note: the last 32-bit release of Matlab on Linux was R2012a

assert(strncmp(computer('arch'),'glnx',4),'Platform does not appear to be Linux.');

mym_base = fileparts(fileparts(mfilename('fullpath')));
mym_src = fullfile(mym_base, 'src');
build_out = fullfile(mym_base, 'build', mexext());
distrib_out = fullfile(mym_base, 'distribution', mexext());

% Set up input and output directories
mysql_base = fullfile(mym_base, 'mysqlclient');
if strfind(mexext(),'glx') %#ok<STRIFCND>
    % 32-bit... use mysql connector from MySQL 6.6.1
    mysql_base = fullfile(mym_base, 'mysql-connector');
end    
mysql_include = fullfile(mysql_base, 'include');
mysql_lib = fullfile(mysql_base, ['lib_' mexext()]);

inc = {mysql_include};
lib = {mysql_lib};

% check for subdirectories in mysql_lib
d = dir(fullfile(mysql_lib,'**'));
d = d(arrayfun(@(x) x.isdir && ~ismember(x.name,{'.','..'}),d));
if ~isempty(d)
    lib = cat(2,lib,arrayfun(@(x) fullfile(x.folder,x.name),d,'UniformOutput',false)');
end
mysql_lib = lib; % note: cell array

platform_include = fullfile(mysql_base, ['include_' mexext()]);
if exist(platform_include,'dir')
    inc = cat(2,inc,platform_include);
end

mariadb_lib = fullfile(mym_base, ['maria-plugin/','lib_',mexext()]);
if exist(mariadb_lib,'dir')
    lib = cat(2,lib,mariadb_lib);
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
    '-lmysqlclient', ...
    'LINKLIBS="$LINKLIBS -Wl,-rpath,\$ORIGIN -Wl,-z,origin"', ...
    '-lz', ...
    fullfile(mym_src, 'mym.cpp'));

% Pack mex with all dependencies into distribution directory
copyfile(['mym.' mexext()], distrib_out);
copyfile(fullfile(mym_src, 'mym.m'), distrib_out);
for ii = 1:numel(mysql_lib)
  dst = strrep(mysql_lib{ii},mysql_lib{1},'');
  copyfile(fullfile(mysql_lib{ii},'lib*'), fullfile(distrib_out,dst));
end
if exist(mariadb_lib,'dir')
    copyfile(fullfile(mariadb_lib, '*.so'), distrib_out);
end
if exist(zlib_lib,'dir')
    copyfile(fullfile(zlib_lib, '*'), distrib_out);
end
