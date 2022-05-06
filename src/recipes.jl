using Printf
using RecipesBase

function indices(compression, x) 

    step = compression ? 8 : 1
    1:step:length(x)

end

function solution_surface( problem :: Problem, time, compression )

    η, v, x, t = solution(problem, t = time)
    i = indices(compression, x)
    x[i], η[i], t

end

function solution_surface( problem :: Problem, x̃ :: AbstractArray, time, compression )

    η, v, x, t = solution(problem; x = x̃, t = time, interpolation = false)
    i = indices(compression, x)
    x[i], η[i], t

end

function solution_fourier( problem, time, compression )

    η, v, y, t = solution(problem, t = time)
    fftη = fft(η)
    x = fftshift(Mesh(y).k)
    y = eps(1.0) .+ abs.(fftshift(fftη))
    i = indices(compression, x)
    x[i], y[i]

end

function solution_velocity(problem, time, compression )

    η, v, x, t = solution(problem, t = time)
	x, v, t

end
   

@recipe function f(problem::Problem; time = nothing, var = :surface, compression = false)

	if var == :fourier

		@series begin 

            title --> "Fourier coefficients (log scale)"
            label --> problem.label
            xlabel --> "frequency"
            ylabel --> "amplitude"
            yscale := :log10

            solution_fourier( problem, time, compression ) 

		end

	end

	if var == :surface

		@series begin 

            x, η, t = solution_surface( problem, time, compression ) 

            title --> @sprintf("surface deformation at t= %7.3f", t)
            label --> problem.label
            xlabel --> "x"
            ylabel --> "η"

            x, η

		end

	end

	if var == :velocity

		@series begin 

            x, v, t = solution_velocity( problem, time, compression ) 

            title --> @sprintf("Tangential velocity at t= %7.3f", t)
            label --> problem.label
            xlabel --> "x"
            ylabel --> "v"

            x, v

		end

	end

end

@recipe function f(problem::Problem, x̃::AbstractArray; t = nothing, var = :surface)

    if var == :surface

		@series begin 

            x, η, t = solution_surface( problem, x̃, t, false )

            title --> @sprintf("surface deformation at t= %7.3f", t)
            label --> problem.label
            xlabel --> "x"
            ylabel --> "η"

            x, η

		end

	end

end


@recipe function f(problems::Vector{Problem}; time = nothing, compression = false)

	surface = get(plotattributes, :surface, true)
	fourier = get(plotattributes, :fourier, false)
	velocity = get(plotattributes, :quiver, false)

    layout := (surface+velocity+fourier, 1)

    for (i,p) in enumerate(problems)

	   n = 0

       if surface
		   n += 1
           @series begin
               x, η, t = solution_surface(p, time, compression)
               title --> @sprintf("Surface deformation at t=%7.3f", t)
               xlabel --> "x"
               ylabel --> "η"
               label --> p.label
               subplot := n
               x, η
           end
	   end

	   if velocity
		   n += 1
           @series begin
		       x, v, t = solution_velocity(p, time, compression)
		       title --> @sprintf("Tangential velocity at t=%7.3f",t)
               xlabel --> "x"
               ylabel --> "v"
               subplot := n
		       x, v
	       end
	   end

       if fourier
		   n += 1
           @series begin
               x, y = solution_fourier(p, time, compression)
               title --> "Fourier coefficients (log scale)"
               xlabel --> "frequency"
               ylabel --> "amplitude"
               label --> p.label
               subplot := n
               yscale := :log10
               x, y
           end
       end

    end

end

@userplot PlotDifferences

@recipe function f(e::PlotDifferences)

    pairs, problems, time = _differences_args( e.args )

    for (i, j) in pairs

	    x1, η1, t = solution_surface(problems[i], time, false)
	    x2, η2, t = solution_surface(problems[j], time, false)

        @series begin
            xlabel := "x"
            ylabel := "η"
	        label := "$(problems[i].label) - $(problems[j].label)"
	        title := @sprintf("difference (surface deformation) at t=%7.3f", t)
            x1, η1 .- η2
        end

    end

end

function _differences_args( (problem1, problem2 ) :: Tuple{Problem, Problem})
		
     [(1,2)], (problem1, problem2), nothing
           
end

function _differences_args( (problem1, problem2, time ) :: Tuple{Problem, Problem, Real})
		
     [(1,2)], (problem1, problem2), time
           
end

function _differences_args( (problems,) :: Tuple{Vector{Problem}})
		
	@show pairs = [(i,j) for i in eachindex(problems) for j in 1:i-1]
    
    pairs, problems, nothing

end

function _differences_args( (problems, time) :: Tuple{Vector{Problem}, Real})
		
	@show pairs = [(i,j) for i in eachindex(problems) for j in 1:i-1]
    
    pairs, problems, time

end