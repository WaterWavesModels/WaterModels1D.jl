# # Workspace
#
#md # [`notebook`](@__NBVIEWER_ROOT_URL__notebooks/two_problems.ipynb)
#
using WaterWaves1D, Plots, FFTW;

gr();

#---- parameters
param = (
    μ = 0.1,
    ϵ = 1,
    N = 2^10, # number of collocation points
    L = 2*π,# size of the mesh (-L,L)
    T = 1,# final time of computation
    dt = 0.001,  # timestep
);


#---- initial data
δ0 = 0.1
δ = 0.01

ph = 3/2
pu = 2
ζ0(x) = δ0^ph *  cos.(x/δ0);#zero(x);
u0(x) = cos.(x) .+ δ0^pu *  cos.(x/δ0);#zero(x);

ζ(x) = δ^ph *  cos.(x/δ);#zero(x);
u(x) = cos.(x) .+ δ^pu *  cos.(x/δ);#zero(x);

#u(x) =  exp.(-abs.(x).^(1.5)).*exp.(-x.*x);
#ζ0(x) = exp.(-x.*x);#zero(x);
#u0(x) =  cos.(x).*exp.(-x.*x);

init = Init(ζ, u);
init0 = Init(ζ0, u0);
# ζ et v sont des fonctions.
# Init les mets sous une forme utilisable par le programme


#---- models to compare
#models = AbstractModel[]


pWW= Problem( WaterWaves(param; dealias = 1) , init, param)


#p0 = Problem( Choi(param; iterate=false,M=1, dealias = 1) , init, param)
p1 = Problem( Choi(param; M=1, reg = false, label="δ", dealias = 1) , init, param)
p2 = Problem( Choi(param; M=1, reg = false, label="δ0", dealias = 1) , init0, param)


#problems = Problem[]
#for model in models
#    push!(problems, Problem(model, init, param;solver=s))
#end
problems = [pWW p1 p2] 
#problems = [pWW pGN pFGa pFGb pFGc] 

#---- computation
for problem in problems
    @time solve!(problem)
end

#---- visualization
plt=plot(problems;T=1,var=[:surface])
plt=plot(problems[2];T=0.1,var=[:surface,:velocity,:fourier])
plt=plot!(problems[3];T=0.1,var=[:surface,:velocity,:fourier])

#plot(problems,var=[:differences],T=2)

plot(problems[[2;3]],var=[:difference,:difference_velocity],T=1,legend=:bottomleft)
plot(problems[[2;6]],var=[:difference,:difference_velocity],T=1,legend=:bottomleft)


@gif for time in LinRange(0,2,101)
    plt=plot([pFG3a,pGN],var=[:differences],T=time,legend=:bottomleft,xlims=(0,10),ylims=(-1e-5,1e-5));
    plot!(plt,[pFG3b,pGN],var=[:differences],T=time,legend=:bottomleft,xlims=(0,10),ylims=(-1e-5,1e-5));

end

# Attention au scaling a revoir !
# Faire la derivee en temps



function norm(p;T=Inf::AbstractFloat,a,μ,s=0)
    T=min(max(T,0),p.times.ts[end])
	index = findfirst(p.times.ts.>=T)
	η,v,u,p,w,x = (p.model.mapfrofull)(p.data.U[index])
	mesh=Mesh(x)
    ∂ₓ=1im*mesh.k
    |(x)=maximum(abs.(x))
    
    if s==0
        return |(η),|(u),|(p),|(w)
    else
        return |(ifft(∂ₓ.^s.*fft(η))),|(ifft(∂ₓ.^s.*fft(u))),|(ifft(∂ₓ.^s.*fft(p))),|(ifft(∂ₓ.^s.*fft(w)))
    end

end

function norms(p;T=nothing,a,μ,s=0,rel=false)
    if isnothing(T)  T = p.times.ts end
    N=zeros(length(T),4)
    j=0
    if rel == true N0 = sum(norm(p;T=T[1],a=a,μ=μ,s=s)) else N0=1 end

    for t in T
        j+=1
        n=norm(p;T=t,a=a,μ=μ,s=s)
        N[j,:].=n./N0
    end
    return N
end

function norm(p1,p2;T=Inf::AbstractFloat,a,μ)
    T=min(max(T,0),p1.times.ts[end],p2.times.ts[end])
	i1 = findfirst(p1.times.ts.>=T)
	η1,v1,u1 = (p1.model.mapfrofull)(p1.data.U[i1])
	i2 = findfirst(p2.times.ts.>=T)
	η2,v2,u2 = (p2.model.mapfrofull)(p2.data.U[i2])
	mesh=Mesh(x)
    ∂ₓ=1im*mesh.k
    |(x)=maximum(abs.(x))
    
    return |(η1-η2),|(u1-u2)
    
end

function norms(p1,p2;T=nothing,a,μ,rel=false)
    if isnothing(T) T = p1.times.ts end
    N=zeros(length(T),2)
    j=0
    if rel == true N0 = sum(norm(p1,p2;T=T[1],a=a,μ=μ)) else N0=1 end

    for t in T
        j+=1
        n=norm(p1,p2;T=t,a=a,μ=μ)
        N[j,:].=n./N0
    end
    return N
end


plot(norms(pFG3b;a=100,μ=0.01,s=2),label=["η" "u" "p" "w"])

plot(norms(pGN,pFG1c;a=100,μ=0.01),label=["Δη" "Δu"])


errid0=[sum(norm(pGN,pFG1a;a=100,μ=0.01)),
    sum(norm(pGN,pFG2a;a=100,μ=0.01)),
    sum(norm(pGN,pFG3a;a=100,μ=0.01))]
errid1=[sum(norm(pGN,pFG1b;a=100,μ=0.01)),
    sum(norm(pGN,pFG2b;a=100,μ=0.01)),
    sum(norm(pGN,pFG3b;a=100,μ=0.01))]
errid2=[sum(norm(pGN,pFG1c;a=100,μ=0.01)),
    sum(norm(pGN,pFG2c;a=100,μ=0.01)),
    sum(norm(pGN,pFG3c;a=100,μ=0.01))]


scatter([20,100,200],errid0,label="no preparation")
scatter!([20,100,200],errid1,label="w well-prepared")
scatter!([20,100,200],errid2,label="w and p well-prepared")
plot!(xscale=:log10,yscale=:log10,legend=:bottomleft,
        xlabel="a",ylabel="difference (L∞)",
        title="difference between GN and LCT")


scatter!([(200,sum(norm(pGN,pFG3c;a=100,μ=0.01)))])
scatter!([(20,sum(norm(pGN,pFG1c;a=20,μ=0.01)[1]))])
norm(pGN,pFG2c;a=100,μ=0.01)

savefig("err.pdf")


Z .= zero(FFT);
for m in 0:M
Z+=Diagonal(h.^(2*m))*IFFT*Diagonal((Dμ.^(m)))/factorial(2*m);
end
L=FFT*Z;