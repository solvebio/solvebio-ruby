module SolveBio
    class ListObject < SolveObject

        def [](k)
            case k
            when String, Symbol
                super
            else
                raise ArgumentError.new("ListObject types only support String keys. Try: #data[#{k.inspect}])")
            end
        end

        def retrieve(id)
            response = Client.request('get', "#{url}/#{id}")
            Util.to_solve_object(response)
        end

        def all(params={})
            resp = Client.request('get', url, {:params => params})
            Util.to_solve_object(resp)
        end

        def create(params={})
            resp = Client.request('post', url, {:params => params})
            Util.to_solve_object(resp)
        end

        def next_page(params={})
            if self.links.next
                resp = Client.request('get', self.links.next, {:params => params})
                Util.to_solve_object(resp)
            end
            return nil
        end

        def prev_page(params={})
            if self.links.prev
                resp = Client.request('get', self.links.prev, {:params => params})
                Util.to_solve_object(resp)
            end
            return nil
        end

        def at(i)
            self.to_a[i]
        end

        def to_a
            return Util.to_solve_object(self.data)
        end

        def each(*pass)
            return self unless block_given?
            i = 0
            ary = self.dup
            done = false
            until done
                if i >= ary.data.size
                    ary = next_page
                    break unless ary
                    i = 0
                end
                yield(ary.at(i))
                i += 1
            end
            return self
        end

        def first
            self.data[0]
        end
    end
end
