classdef PRM_test < PRM
    methods
       function prm = PRM_test(varargin)
            prm = prm@PRM(varargin{:});
        end
        
    end
    methods (Access='protected')
    % private methods
        % create the roadmap
        function create_roadmap(prm)
            disp('foi');
            for j=1:prm.npoints
                % pick a point not in obstacle
                while true
                    x = prm.randi(numcols(prm.occgrid));
                    y = prm.randi(numrows(prm.occgrid));
                    if prm.occgrid(y,x) == 0
                        break;
                    end
                end
                new = [x; y];

                vnew = prm.graph.add_node(new);

                [d,v] = prm.graph.distances(new);
                % test neighbours in order of increasing distance
                for i=1:length(d)
                    if v(i) == vnew
                        continue;
                    end
                    if d(i) > prm.distthresh
                        continue;
                    end
                    if ~prm.testpath(new, prm.graph.coord(v(i)))
                        continue;
                    end
                    prm.graph.add_edge(vnew, v(i));
                end
            end
        end

    end % private methods

end % classdef
