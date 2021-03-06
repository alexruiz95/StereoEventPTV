function [A,b] = constructAmatrixdown(position, dx_kernel, dy_kernel, dz_kernel, lap_x, uv,  x2, y2, z2, bound_cond,...
    param_test, lambda1, lambda2, lambda3, npixels, iteout, itenumber, numframe, v1tx, v1ty, v2tx, v2ty, trans1, trans2, levels,pyramid_levels)
%% y == z
%% u == r
pos_tmp = reshape(position, npixels, numframe);
pos = pos_tmp(:,itenumber);
tmpuv = uv;
possquare = pos.^2;
U = reshape(tmpuv(:,:,:,1, itenumber), npixels, 1);
V = reshape(tmpuv(:,:,:,2, itenumber), npixels, 1);
W = reshape(tmpuv(:,:,:,3, itenumber), npixels, 1);
s = size(x2);
% lambda3 = 1e-5;
% mask for temporal coherence boundary
[H, w, D] = size( uv(:,:,:,1) );
mask = zeros( H, w, D );

mask( 3:end-3, 3:end-3, 3:end-3 ) = 1;
mask =  reshape(mask,npixels,1);

% bound_cond='replicate';
%% Projection operator for data term
proj1 = @(uvw) ( param_test .*trans1(1,1) .* ( trans1(1,1) * uvw(1:npixels) + trans1(2,1) * uvw(npixels+1:2*npixels) + trans1(3,1) .* uvw(2*npixels+1:3*npixels)) + ...
    param_test .*trans1(1,2)  .*(trans1(1,2) *  uvw(1:npixels) + trans1(2,2)*uvw(npixels+1:2*npixels) + trans1(3,2)*uvw(2*npixels+1:3*npixels)) + ...
    param_test .*trans2(1,1) .*(trans2(1,1)*uvw(1:npixels) + trans2(2,1) *uvw(npixels+1:2*npixels) + trans2(3,1) *uvw(2*npixels+1:3*npixels)) + ...
    param_test .*trans2(1,2) .*(trans2(1,2)*uvw(1:npixels) + trans2(2,2)*uvw(npixels+1:2*npixels) + trans2(3,2) *uvw(2*npixels+1:3*npixels)) ); % 3d to 2d Projection
proj2 = @(uvw) ( param_test .*trans1(2,1) .* ( trans1(1,1) * uvw(1:npixels) + trans1(2,1) * uvw(npixels+1:2*npixels) + trans1(3,1) .* uvw(2*npixels+1:3*npixels)) + ...
    param_test .*trans1(2,2) .*(trans1(1,2) *  uvw(1:npixels) + trans1(2,2)*uvw(npixels+1:2*npixels) + trans1(3,2)*uvw(2*npixels+1:3*npixels)) + ...
    param_test .*trans2(2,1) .*(trans2(1,1)*uvw(1:npixels) + trans2(2,1) *uvw(npixels+1:2*npixels) + trans2(3,1) *uvw(2*npixels+1:3*npixels)) + ...
    param_test .*trans2(2,2) .*(trans2(1,2)*uvw(1:npixels) + trans2(2,2)*uvw(npixels+1:2*npixels) + trans2(3,2) *uvw(2*npixels+1:3*npixels)) ); % 3d to 2d Projection

proj3 = @(uvw) ( param_test .*trans1(3,1) .* ( trans1(1,1) * uvw(1:npixels) + trans1(2,1) * uvw(npixels+1:2*npixels) + trans1(3,1) .* uvw(2*npixels+1:3*npixels)) + ...
    param_test .*trans1(3,2)  .*(trans1(1,2) *  uvw(1:npixels) + trans1(2,2)*uvw(npixels+1:2*npixels) + trans1(3,2)*uvw(2*npixels+1:3*npixels)) + ...
    param_test .*trans2(3,1) .*(trans2(1,1)*uvw(1:npixels) + trans2(2,1) *uvw(npixels+1:2*npixels) + trans2(3,1) *uvw(2*npixels+1:3*npixels)) + ...
    param_test .*trans2(3,2) .*(trans2(1,2)*uvw(1:npixels) + trans2(2,2)*uvw(npixels+1:2*npixels) + trans2(3,2) *uvw(2*npixels+1:3*npixels)) ); % 3d to 2d Projection
%% divergence operator
diverg = @(uvw) (reshape(imfilter(reshape(uvw(1:npixels), s),dy_kernel,bound_cond,'conv'), npixels,1) + ...
    reshape(imfilter(reshape(uvw(npixels+1:2*npixels), s),dx_kernel,bound_cond,'conv'), npixels,1) + ...
    reshape(imfilter(reshape(uvw(2*npixels+1:3*npixels), s),dz_kernel,bound_cond,'conv'), npixels,1));
divx = @(uvw) reshape(imfilter(reshape(diverg(uvw), s),dy_kernel, bound_cond), npixels,1); % divergence term
divy = @(uvw) reshape(imfilter(reshape(diverg(uvw),s) ,dx_kernel, bound_cond), npixels,1); % divergence term
divz = @(uvw) reshape(imfilter(reshape(diverg(uvw),s) ,dz_kernel, bound_cond), npixels,1); % divergence term
%% A x = b construction
if itenumber == 1 % for first frame
    if iteout == 1 && levels==pyramid_levels
        A =@(uvw) [possquare .* proj1(uvw)+ lambda1 * reshape(imfilter(reshape(uvw(1:npixels), size( uv(:,:,:,1) )),lap_x,bound_cond), npixels,1) + lambda3 * divx(uvw) ; ...
            possquare .* proj2(uvw)+ lambda1 * reshape(imfilter(reshape(uvw(npixels+1:2*npixels), size( uv(:,:,:,1) )),lap_x,bound_cond), npixels,1) + lambda3 * divy(uvw);...
            possquare .* proj3(uvw)+ lambda1 * reshape(imfilter(reshape(uvw(2*npixels+1:3*npixels), size( uv(:,:,:,1) )),lap_x,bound_cond), npixels,1) + lambda3 * divz(uvw)];
        
        b = -[possquare.*proj1([U;V;W])- pos .* (param_test * (trans1(1,1) * v1tx + trans1(1,2) * v1ty) + param_test * (trans2(1,1) * v2tx + trans2(1,2) * v2ty))+ lambda1 * reshape(imfilter(reshape(U, size( uv(:,:,:,1))),lap_x,bound_cond), npixels,1) + lambda3 * divx([U;V;W]);...
            possquare.*proj2([U;V;W])- pos .* (param_test * (trans1(2,1) * v1tx + trans1(2,2) * v1ty) + param_test * (trans2(2,1) * v2tx + trans2(2,2) * v2ty))+ lambda1 * reshape(imfilter(reshape(V, size( uv(:,:,:,1))),lap_x,bound_cond), npixels,1)+ lambda3 * divy([U;V;W]);...
            possquare.*proj3([U;V;W])- pos .* (param_test * (trans1(3,1) * v1tx + trans1(3,2) * v1ty) + param_test * (trans2(3,1) * v2tx + trans2(3,2) * v2ty))+ lambda1 * reshape(imfilter(reshape(W, size( uv(:,:,:,1))),lap_x,bound_cond), npixels,1)+ lambda3 * divz([U;V;W]);];
    else
        xb = x2 + tmpuv(:,:,:,1,itenumber);
        yb = y2 + tmpuv(:,:,:,2,itenumber);
        zb = z2 + tmpuv(:,:,:,3,itenumber);
        warpbackuv = cat(4, interp_new(x2,y2,z2,uv(:,:,:,1,itenumber+1), xb,yb,zb,'cubic'), ...
            interp_new(x2,y2,z2,uv(:,:,:,2,itenumber+1), xb,yb,zb,'cubic'),...
            interp_new(x2,y2,z2,uv(:,:,:,3,itenumber+1), xb,yb,zb,'cubic'));
        warpbackuv = reshape(warpbackuv, npixels, 3);
        mask = mask.*pos_tmp(:,itenumber+1);
        A =@(uvw) [possquare .* proj1(uvw)+ lambda1 * reshape(imfilter(reshape(uvw(1:npixels), size( uv(:,:,:,1) )),lap_x,bound_cond), npixels,1)+lambda2.*mask.*uvw(1:npixels)+ lambda3 * divx(uvw); ...
            possquare .* proj2(uvw) + lambda1 * reshape(imfilter(reshape(uvw(npixels+1:2*npixels), size( uv(:,:,:,1) )),lap_x,bound_cond), npixels,1)+lambda2.*mask.*uvw(npixels+1:2*npixels)+ lambda3 * divy(uvw); ...
            possquare .* proj3(uvw)+ lambda1 * reshape(imfilter(reshape(uvw(2*npixels+1:3*npixels), size( uv(:,:,:,1) )),lap_x,bound_cond), npixels,1)+lambda2.*mask.*uvw(2*npixels+1:3*npixels)+ lambda3 * divz(uvw);];
        b = -[possquare.*proj1([U;V;W])- pos .* (param_test * (trans1(1,1) * v1tx + trans1(1,2) * v1ty) + param_test * (trans2(1,1) * v2tx + trans2(1,2) * v2ty))+ lambda1 * reshape(imfilter(reshape(U, size( uv(:,:,:,1))),lap_x,bound_cond), npixels,1)+ lambda2.*mask.*(U-warpbackuv(:,1))+ lambda3 * divx([U;V;W]); ...
            possquare.*proj2([U;V;W])- pos .* (param_test * (trans1(2,1) * v1tx + trans1(2,2) * v1ty) + param_test * (trans2(2,1) * v2tx + trans2(2,2) * v2ty))+ lambda1 * reshape(imfilter(reshape(V, size( uv(:,:,:,1))),lap_x,bound_cond), npixels,1)+ lambda2.*mask.*(V-warpbackuv(:,2))+ lambda3 * divy([U;V;W]); ...
            possquare.*proj3([U;V;W])- pos .* (param_test * (trans1(3,1) * v1tx + trans1(3,2) * v1ty) + param_test * (trans2(3,1) * v2tx + trans2(3,2) * v2ty))+ lambda1 * reshape(imfilter(reshape(W, size( uv(:,:,:,1))),lap_x,bound_cond), npixels,1)+ lambda2.*mask.*(W-warpbackuv(:,3))+ lambda3 * divz([U;V;W])];
    end
    
elseif itenumber < numframe % for middle frame
    xb = x2 + tmpuv(:,:,:,1,itenumber);
    yb = y2 + tmpuv(:,:,:,2,itenumber);
    zb = z2 + tmpuv(:,:,:,3,itenumber);
    warpbackuv = cat(4, interp_new(x2,y2,z2,uv(:,:,:,1,itenumber+1), xb,yb,zb,'cubic'), ...
        interp_new(x2,y2,z2,uv(:,:,:,2,itenumber+1), xb,yb,zb,'cubic'),...
        interp_new(x2,y2,z2,uv(:,:,:,3,itenumber+1), xb,yb,zb,'cubic'));
    warpbackuv = reshape(warpbackuv, npixels, 3);
    mask = mask.*pos_tmp(:,itenumber+1);
    xf = x2 - tmpuv(:,:,:,1,itenumber-1);
    yf = y2 - tmpuv(:,:,:,2,itenumber-1);
    zf = z2 - tmpuv(:,:,:,3,itenumber-1);
    warpforwarduv = cat(4, interp_new(x2,y2,z2,uv(:,:,:,1,itenumber-1), xf,yf,zf,'cubic'), ...
        interp_new(x2,y2,z2,uv(:,:,:,2,itenumber-1), xf,yf,zf,'cubic'),...
        interp_new(x2,y2,z2,uv(:,:,:,3,itenumber-1), xf,yf,zf,'cubic'));
    warpforwarduv = reshape(warpforwarduv, npixels, 3);
    maskf = mask.*pos_tmp(:,itenumber-1);
    if iteout == 1
        A =@(uvw) [possquare .*proj1(uvw)+ lambda1 * reshape(imfilter(reshape(uvw(1:npixels), size( uv(:,:,:,1) )),lap_x,bound_cond), npixels,1)+lambda2.*maskf.*uvw(1:npixels)+ lambda3 * divx(uvw); ...
            possquare .*proj2(uvw)+ lambda1 * reshape(imfilter(reshape(uvw(npixels+1:2*npixels), size( uv(:,:,:,1) )),lap_x,bound_cond), npixels,1)+lambda2.*maskf.*uvw(npixels+1:2*npixels)+ lambda3 * divy(uvw); ...
            possquare .*proj3(uvw)+ lambda1 * reshape(imfilter(reshape(uvw(2*npixels+1:3*npixels), size( uv(:,:,:,1) )),lap_x,bound_cond), npixels,1)+lambda2.*maskf.*uvw(2*npixels+1:3*npixels)+ lambda3 * divz(uvw); ];
        
        b = -[possquare.*proj1([U;V;W])- pos .* (param_test * (trans1(1,1) * v1tx + trans1(1,2) * v1ty) + param_test * (trans2(1,1) * v2tx + trans2(1,2) * v2ty))+ lambda1 * reshape(imfilter(reshape(U, size( uv(:,:,:,1))),lap_x,bound_cond), npixels,1)+lambda2.*maskf.*(U-warpforwarduv(:,1))+ lambda3 * divx([U;V;W]); ...
            possquare.*proj2([U;V;W])- pos .* (param_test * (trans1(2,1) * v1tx + trans1(2,2) * v1ty) + param_test * (trans2(2,1) * v2tx + trans2(2,2) * v2ty))+ lambda1 * reshape(imfilter(reshape(V, size( uv(:,:,:,1))),lap_x,bound_cond), npixels,1)+lambda2.*maskf.*(V-warpforwarduv(:,2))+ lambda3 * divy([U;V;W]); ...
            possquare.*proj3([U;V;W])- pos .* (param_test * (trans1(3,1) * v1tx + trans1(3,2) * v1ty) + param_test * (trans2(3,1) * v2tx + trans2(3,2) * v2ty))+ lambda1 * reshape(imfilter(reshape(W, size( uv(:,:,:,1))),lap_x,bound_cond), npixels,1)+lambda2.*maskf.*(W-warpforwarduv(:,3))+ lambda3 * divz([U;V;W])];
        
    else
        A =@(uvw) [possquare .*proj1(uvw)+ lambda1 * reshape(imfilter(reshape(uvw(1:npixels), size( uv(:,:,:,1) )),lap_x,bound_cond), npixels,1)+lambda2.*mask.*uvw(1:npixels)+lambda2.*maskf.*uvw(1:npixels)+ lambda3 * divx(uvw); ...
            possquare .*proj2(uvw)+ lambda1 * reshape(imfilter(reshape(uvw(npixels+1:2*npixels), size( uv(:,:,:,1) )),lap_x,bound_cond), npixels,1)+lambda2.*mask.*uvw(npixels+1:2*npixels)+lambda2.*maskf.*uvw(npixels+1:2*npixels)+ lambda3 * divy(uvw); ...
            possquare .*proj3(uvw)+ lambda1 * reshape(imfilter(reshape(uvw(2*npixels+1:3*npixels), size( uv(:,:,:,1) )),lap_x,bound_cond), npixels,1)+lambda2.*mask.*uvw(2*npixels+1:3*npixels)+lambda2.*maskf.*uvw(2*npixels+1:3*npixels)+ lambda3 * divz(uvw); ];
        
        b = -[possquare.*proj1([U;V;W])- pos .* (param_test * (trans1(1,1) * v1tx + trans1(1,2) * v1ty) + param_test * (trans2(1,1) * v2tx + trans2(1,2) * v2ty))+ lambda1 * reshape(imfilter(reshape(U, size( uv(:,:,:,1))),lap_x,bound_cond), npixels,1)+lambda2.*(maskf.*(U-warpforwarduv(:,1))+mask.*(U-warpbackuv(:,1)))+ lambda3 * divx([U;V;W]); ...
            possquare.*proj2([U;V;W])- pos .* (param_test * (trans1(2,1) * v1tx + trans1(2,2) * v1ty) + param_test * (trans2(2,1) * v2tx + trans2(2,2) * v2ty))+ lambda1 * reshape(imfilter(reshape(V, size( uv(:,:,:,1))),lap_x,bound_cond), npixels,1)+lambda2.*(maskf.*(V-warpforwarduv(:,2))+mask.*(V-warpbackuv(:,2)))+ lambda3 * divy([U;V;W]); ...
            possquare.*proj3([U;V;W])- pos .* (param_test * (trans1(3,1) * v1tx + trans1(3,2) * v1ty) + param_test * (trans2(3,1) * v2tx + trans2(3,2) * v2ty))+ lambda1 * reshape(imfilter(reshape(W, size( uv(:,:,:,1))),lap_x,bound_cond), npixels,1)+lambda2.*(maskf.*(W-warpforwarduv(:,3))+mask.*(W-warpbackuv(:,3)))+ lambda3 * divz([U;V;W])];
        
    end
    
else % for last frame
    xf = x2 - tmpuv(:,:,:,1,itenumber-1);
    yf = y2 - tmpuv(:,:,:,2,itenumber-1);
    zf = z2 - tmpuv(:,:,:,3,itenumber-1);
    warpforwarduv = cat(4, interp_new(x2,y2,z2,uv(:,:,:,1,itenumber-1), xf,yf,zf,'cubic'), ...
        interp_new(x2,y2,z2,uv(:,:,:,2,itenumber-1), xf,yf,zf,'cubic'),...
        interp_new(x2,y2,z2,uv(:,:,:,3,itenumber-1), xf,yf,zf,'cubic'));
    warpforwarduv = reshape(warpforwarduv, npixels, 3);
    maskf=mask.*pos_tmp(:,itenumber-1);
    A =@(uvw) [possquare .*proj1(uvw)+ lambda1 * reshape(imfilter(reshape(uvw(1:npixels), size( uv(:,:,:,1) )),lap_x,bound_cond), npixels,1)+lambda2.*maskf.*uvw(1:npixels) + lambda3 * divx(uvw); ...%*gridx(uvw); ...
        possquare .*proj2(uvw)+ lambda1 * reshape(imfilter(reshape(uvw(npixels+1:2*npixels), size( uv(:,:,:,1) )),lap_x,bound_cond), npixels,1)+lambda2.*maskf.*uvw(npixels+1:2*npixels)+ lambda3 * divy(uvw); ...%*gridy(uvw);...
        possquare .*proj3(uvw)+ lambda1 * reshape(imfilter(reshape(uvw(2*npixels+1:3*npixels), size( uv(:,:,:,1) )),lap_x,bound_cond), npixels,1)+lambda2.*maskf.*uvw(2*npixels+1:3*npixels)+ lambda3 * divz(uvw); ];% ...%*gridz
    
    b = -[possquare.*proj1([U;V;W])- pos .* (param_test * (trans1(1,1) * v1tx + trans1(1,2) * v1ty) + param_test * (trans2(1,1) * v2tx + trans2(1,2) * v2ty))+ lambda1 * reshape(imfilter(reshape(U, size( uv(:,:,:,1))),lap_x,bound_cond), npixels,1)+lambda2.*maskf.*(U-warpforwarduv(:,1))+ lambda3 * divx([U;V;W]); ...
        possquare.*proj2([U;V;W])- pos .* (param_test * (trans1(2,1) * v1tx + trans1(2,2) * v1ty) + param_test * (trans2(2,1) * v2tx + trans2(2,2) * v2ty))+ lambda1 * reshape(imfilter(reshape(V, size( uv(:,:,:,1))),lap_x,bound_cond), npixels,1)+lambda2.*maskf.*(V-warpforwarduv(:,2))+ lambda3 * divy([U;V;W]); ...
        possquare.*proj3([U;V;W])- pos .* (param_test * (trans1(3,1) * v1tx + trans1(3,2) * v1ty) + param_test * (trans2(3,1) * v2tx + trans2(3,2) * v2ty))+ lambda1 * reshape(imfilter(reshape(W, size( uv(:,:,:,1))),lap_x,bound_cond), npixels,1)+lambda2.*maskf.*(W-warpforwarduv(:,3))+ lambda3 * divz([U;V;W])];
    
end
