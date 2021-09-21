function f = eval2(SO3F,rot,varargin)

N = SO3F.bandwidth;

% If SO3F is real valued we have the symmetry properties (*) and (**) for 
% the Fourier coefficients. We will use this to speed up computation.
if SO3F.isReal

  %ind = mod(N+1,2);
  % create ghat -> k x l x j
  %   k = -N+1:N
  %   l =    0:N+ind    -> use ghat(-k,-l,-j)=conj(ghat(k,l,j))        (*)
  %   j = -N+1:N        -> use ghat(k,l,-j)=(-1)^(k+l)*ghat(k,l,j)     (**)
  % we need to make it 2N+2 as the index set of the NFFT is -(N+1) ... N
  % we use ind in 2nd dimension to get even number of fourier coefficients
  % the additionally indices gives 0-columns in front of ghat
  ghat = compute_ghat(N,SO3F.fhat,'isReal','makeeven');
  
else

  % create ghat -> k x l x j
  % we need to make it 2N+2 as the index set of the NFFT is -(N+1) ... N
  % we can again use (**) to speed up  
  ghat = compute_ghat(N,SO3F.fhat,'makeeven');  
  
end


% nfft
sz = size(rot);
rot = rot(:);
M = length(rot);

% alpha, beta, gamma
abg = Euler(rot,'nfft')'./(2*pi);
abg = (abg + [-0.25;0;0.25]);
abg = [abg(2,:);abg(1,:);abg(3,:)];
abg = mod(abg,1);

% initialize nfft plan
%plan = nfftmex('init_3d',2*N+2,2*N+2,2*N+2,M);
NN = 2*N+2;
N2 = size(ghat,2);
FN = ceil(1.5*NN);
FN2 = ceil(1.5*N2);
plan = nfftmex('init_guru',{3,NN,N2,NN,M,FN,FN2,FN,4,int8(0),int8(0)});


% set rotations as nodes in plan
nfftmex('set_x',plan,abg);

% node-dependent precomputation
nfftmex('precompute_psi',plan);

% set Fourier coefficients
nfftmex('set_f_hat',plan,ghat(:));

% fast fourier transform
nfftmex('trafo',plan);

% get function values from plan
if SO3F.isReal
  % use (*) and shift summation in 2nd index
  f = 2*real((exp(-2*pi*1i*ceil(N/2)*abg(2,:)')).*(nfftmex('get_f',plan)));
else
  f = nfftmex('get_f',plan);
end

f = reshape(f,sz);

end