### A Pluto.jl notebook ###
# v0.16.4

using Markdown
using InteractiveUtils

# ╔═╡ 1c4d22e2-4d58-401e-96b6-1745a3fe5209
begin
	using PlutoUI
	
	using PlutoTest
	using BenchmarkTools
	using BangBang: Empty
	using StaticArrays: SVector
	using MicroCollections
	using Tullio
end

# ╔═╡ 756c8c9f-0c4e-4009-9454-b1f28330b707
begin
	using Transducers
	using Transducers:
	    @next, R_, Transducer, combine, complete, inner, next, start, unwrap, wrap, wrapping
end

# ╔═╡ 7e7204a6-2db7-11ec-0602-7590cdcd6c01
function a(x) 
	2+x
end

# ╔═╡ 72330b0d-3d19-4807-a099-2487ce38f3dc
a()

# ╔═╡ 2442bcc7-2fb0-44ae-b0be-9528f8a51793


# ╔═╡ 329bbaa9-a90d-419d-86aa-9b2658f303f2


# ╔═╡ 5fbb9977-aac7-4c9a-b16d-fe5558d928cd
with_terminal() do
	@code_native a(74)
end

# ╔═╡ ba173400-53c7-47b1-8d25-b9f4e0272ddb
digits(10, base=2) |> reverse

# ╔═╡ 63f1e6d5-b29b-4206-b966-235a28cbccda
mapfoldl

# ╔═╡ 00290cf2-1556-484b-b6e8-8bb02a81a392


# ╔═╡ fc2611e0-94e1-4073-9ee0-f6ed09c3ad72
struct Chunk
	s::String
end

# ╔═╡ f88de2fb-259f-40e7-848b-3d26a871c7a9
struct Segment
    l::String
    A::Vector{String}
    r::String
end

# ╔═╡ 2f3dca61-b71c-4d11-9b79-0db3dc130552
begin
	⊕(x::Chunk, y::Chunk) = Chunk(x.s * y.s)
	⊕(x::Chunk, y::Segment) = Segment(x.s * y.l, y.A, y.r)
	⊕(x::Segment, y::Chunk) = Segment(x.l, x.A, x.r * y.s)
	⊕(x::Segment, y::Segment) =
		Segment(x.l,
				append!(x.A, maybewordv(x.r * y.l), y.A),
				y.r)
	

	maybewordv(s::String) = isempty(s) ? vec0(String) : vec1(s)
end

# ╔═╡ 13cf54c0-ee19-4057-b798-91f5ae7a5f69
segment_or_chunk(c::Char) = c == ' ' ? Segment("", vec0(String), "") : Chunk(string(c))

# ╔═╡ 809eba0f-ef17-4a66-b604-37a2a3438e61
function collectwords(s::String)
	if isempty(s)
		return []
	end
    g = foldxt(⊕, Map(segment_or_chunk), s)
    if g isa Chunk
        return maybewordv(g.s)
    else
        return vcat(maybewordv(g.l), g.A, maybewordv(g.r))
    end
end

# ╔═╡ 3b3ee27a-63f4-4c01-952e-43f9308ef7f3
function collectwords_old(s::String)
    g = mapfoldl(segment_or_chunk, ⊕, s; init=Segment("", [], ""))
    if g isa Char
        return maybewordv(g.s)
    else
        return vcat(maybewordv(g.l), g.A, maybewordv(g.r))
    end
end

# ╔═╡ 13769317-d840-4851-8547-af08688877e0
@benchmark collectwords_old(s)

# ╔═╡ 04b46d58-5157-41b6-8713-5c401432252f
@benchmark collectwords(s)

# ╔═╡ ae2355b2-9e62-4356-8a04-f99f8d01e27b
@test collectwords("This is a sample") == ["This", "is", "a", "sample"]

# ╔═╡ 525b0d59-e492-419e-9240-70d682dd9456
@test collectwords_old("This is a sample") == ["This", "is", "a", "sample"]

# ╔═╡ 268dbea8-4e6b-4fb9-ba7d-fc07372f96d0
@test collectwords(" Here is another sample ") == ["Here", "is", "another", "sample"]

# ╔═╡ 825126f5-e9b7-4c93-ae23-31517b297672
@test collectwords("JustOneWord") == ["JustOneWord"]

# ╔═╡ cc5af8c3-6bce-4bba-b65d-022de74a8cb3
@test collectwords(" ") == []

# ╔═╡ 4534b095-508a-4a53-a0ee-5283132c1809
struct Vacant
    l::String
    r::String
end

# ╔═╡ 9929116d-7d18-4d60-a082-c00bdb4e7cf7
vacant_or_chunk(c::Char) = c == ' ' ? Vacant("", "") : Chunk(string(c))

# ╔═╡ b2c9a44d-3e98-4acf-8cc8-6fc2ee0208d7
begin
	extract(x::Chunk, y::Chunk) = nothing, Chunk(x.s * y.s)
	extract(x::Chunk, y::Vacant) = nothing, Vacant(x.s * y.l, y.r)
	extract(x::Vacant, y::Chunk) = nothing, Vacant(x.l, x.r * y.s)
	extract(x::Vacant, y::Vacant) = maybeword(x.r * y.l), Vacant(x.l, y.r)
	
	maybeword(s) = isempty(s) ? nothing : s
end

# ╔═╡ 83740467-22e0-41ea-bf51-00523f63f541
struct WordsXF <: Transducer end


# ╔═╡ fbaf8bdb-650d-4627-ad25-201352150778
Transducers.start(rf::R_{WordsXF}, init) = wrap(rf, Chunk(""), start(inner(rf), init))


# ╔═╡ 7cd8ac94-f88f-4728-9d51-a35339014fe2
function Transducers.next(rf::R_{WordsXF}, acc, x)
    wrapping(rf, acc) do state, iacc
        word, state = extract(state, x)
        iacc = next(inner(rf), iacc, word)
        return state, iacc
    end
end

# ╔═╡ a662797b-69eb-451d-b206-113a84a261d0
function Transducers.complete(rf::R_{WordsXF}, acc)
    state, iacc = unwrap(rf, acc)
    if state isa Vacant
        pre = @next(inner(rf), start(inner(rf), Init), maybeword(state.l))
        iacc = combine(inner(rf), pre, iacc)  # prepending `state.l`
        iacc = @next(inner(rf), iacc, maybeword(state.r))  # appending `state.r`
    else
        @assert state isa Chunk
        iacc = @next(inner(rf), iacc, maybeword(state.s))
    end
    return complete(inner(rf), iacc)
end

# ╔═╡ aa19e325-67be-4a2b-a8a0-96c1890e0c70
function Transducers.combine(rf::R_{WordsXF}, a, b)
    ua, ira = unwrap(rf, a)
    ub, irb = unwrap(rf, b)
    word, uc = extract(ua, ub)
    ira = @next(inner(rf), ira, word)
    irc = combine(inner(rf), ira, irb)
    return wrap(rf, uc, irc)
end

# ╔═╡ 9999d0be-3ec9-4875-bea3-a0884b7d63fe
wordsxf = opcompose(Map(vacant_or_chunk), WordsXF(), Filter(!isnothing))


# ╔═╡ 46767ba5-a002-4176-bd86-38310c49bc07
@test collect(wordsxf, "This is a sample") == ["This", "is", "a", "sample"]

# ╔═╡ 59f3189f-983e-4b81-acbf-76773c81f9c8
@test collect(wordsxf, " Here is another sample ") == ["Here", "is", "another", "sample"]

# ╔═╡ 2711c17f-a8c7-4a3a-8eeb-175a1b0b1292
@test collect(wordsxf, "JustOneWord") == ["JustOneWord"]

# ╔═╡ 5b2904ef-0516-4c83-a670-b05c7a3a800c
@test collect(wordsxf, " ") == []

# ╔═╡ 90187e2e-36ec-4930-8ff2-905e9916564f
@test collect(wordsxf, "") == []

# ╔═╡ 60ba2c19-8b7a-44c5-9236-a264df831828
@benchmark collect(wordsxf, s)

# ╔═╡ 55afcd00-0a5f-4ab8-9b30-7e550d0d21dd
mapreduce

# ╔═╡ bb099473-a2c7-4b55-a51c-f45a0c63c979
1+1

# ╔═╡ f7110269-0599-4b2e-8b93-c877a753f1db


# ╔═╡ bb42fe13-4663-4c79-b66d-1c69ed14090c


# ╔═╡ 6942bc7d-0a37-413e-9a81-09eeb25cc433


# ╔═╡ d45787c6-2a38-474f-994d-50d09d338786
s = """
Lorem ipsum dolor sit amet, consectetur adipiscing elit. Mauris vehicula leo ut lobortis consectetur. Aliquam erat volutpat. Vivamus tincidunt nunc sit amet sapien ultrices hendrerit. Nullam ipsum ipsum, ultrices eu purus ac, aliquam porttitor mauris. Proin dictum pretium finibus. Sed eros lectus, laoreet at lacus quis, convallis porta quam. Maecenas non enim a ex commodo pretium sit amet id urna. Aenean posuere, elit ut facilisis faucibus, velit leo commodo neque, nec vestibulum lectus dolor nec diam. Aliquam quis dictum massa. Quisque urna leo, vestibulum non mi eu, lobortis fermentum odio. Duis non leo eu mauris interdum cursus. Aliquam turpis ligula, mollis eu suscipit quis, sodales at lectus. Donec at sapien sed felis mollis rutrum.

Mauris maximus arcu odio, ut laoreet neque blandit sed. Sed rutrum nunc in erat vulputate, vel tincidunt purus consequat. Aenean in tellus laoreet, aliquet turpis et, consequat ex. Fusce eget lectus diam. Proin dapibus, nunc non venenatis eleifend, ex nisi feugiat odio, non pellentesque velit tortor sed leo. Vestibulum sit amet diam elit. Donec fringilla turpis vitae ipsum feugiat gravida. Fusce maximus metus at suscipit congue. Curabitur eu venenatis nunc. Cras quis leo lacus. Suspendisse ut gravida mi. Donec consequat sapien lacus.

Ut ut euismod justo. Aliquam tristique nisl mi, porta gravida augue fermentum ac. Quisque facilisis dui sit amet viverra dignissim. Nam molestie dapibus facilisis. Vivamus quis mattis eros. Quisque in augue luctus erat porta congue. Nulla egestas, ex et tempus luctus, nunc enim efficitur est, at hendrerit eros nibh at nisi. Suspendisse egestas ornare mi, nec euismod ligula viverra vel. In posuere nec neque at posuere.

Integer vulputate ex a sapien eleifend cursus. Nulla laoreet consectetur malesuada. In nec eleifend quam, a pulvinar lorem. Nulla neque enim, vulputate a iaculis id, rhoncus in ligula. Aenean nec risus sed quam lobortis vulputate sed sit amet arcu. Vestibulum diam arcu, rutrum sit amet justo vitae, luctus convallis nunc. Nulla posuere a nisl quis bibendum.

Pellentesque quis tincidunt nisl, id dapibus leo. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Morbi nec finibus leo. Fusce massa felis, rutrum pellentesque nisl in, finibus pulvinar mi. Donec vel odio elementum, consectetur est eu, sollicitudin mi. Proin condimentum sapien diam, eget tristique nisi cursus eget. In tortor orci, finibus in lacinia a, mattis non tellus. In nisl purus, accumsan egestas urna sed, pretium ullamcorper diam. Aliquam pulvinar ante ut ultricies tincidunt. Fusce at interdum nibh, nec rhoncus massa. Curabitur at volutpat enim.

Vivamus velit leo, varius eget leo id, maximus tincidunt odio. Maecenas vulputate ultricies facilisis. Sed dolor lorem, aliquet sed iaculis eget, congue et leo. Proin mattis vitae justo nec elementum. Curabitur condimentum metus quis bibendum consectetur. In hac habitasse platea dictumst. Curabitur sapien magna, tincidunt in hendrerit quis, faucibus sit amet orci. Aenean ultrices ligula metus, quis ullamcorper augue semper sed. Nam pharetra nec turpis vel laoreet.

Nullam venenatis, eros nec mattis accumsan, magna turpis volutpat nulla, in ornare ex massa ac erat. Nam ornare dapibus nulla, et hendrerit neque semper bibendum. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Vivamus urna nulla, sodales eu neque eu, imperdiet tincidunt eros. Mauris posuere tellus vel varius mollis. Sed nec sagittis justo. Vestibulum ac interdum enim. Integer congue diam vitae diam congue iaculis. Nullam imperdiet fringilla odio a vestibulum.

Aenean laoreet, justo eu porttitor maximus, velit diam luctus nisi, nec mattis nulla tellus lacinia ante. Praesent non erat magna. Nam blandit turpis quis nibh tincidunt finibus. Curabitur quis tellus suscipit, scelerisque eros id, tempus magna. Pellentesque id viverra sapien, eu venenatis tellus. Phasellus lorem justo, porttitor sed enim non, mollis rhoncus justo. Donec vitae pulvinar erat. Curabitur placerat bibendum fermentum. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aenean at bibendum mi. Nam vestibulum dui libero, eu pretium massa volutpat id. Sed id rutrum diam, nec venenatis sapien. In hac habitasse platea dictumst.

Aliquam sit amet tristique risus. Vivamus urna augue, pulvinar et odio et, tincidunt venenatis ex. Mauris fermentum laoreet orci, et dignissim lacus laoreet a. Phasellus non luctus nunc. Nulla nisi lacus, aliquam in volutpat vitae, scelerisque quis sem. Phasellus bibendum lacus et augue dignissim iaculis. Suspendisse potenti. Etiam eget ex at dolor tempus ullamcorper et a tortor. Aliquam sagittis vitae metus non ultricies. Quisque euismod sollicitudin purus non lobortis. Etiam et turpis eu ligula scelerisque sollicitudin at non dui. Maecenas risus velit, hendrerit ut dapibus ut, auctor in lorem.

Proin ac purus et libero convallis cursus. Morbi ac quam convallis, finibus tortor aliquam, faucibus est. Vestibulum semper mollis libero, lacinia dignissim ipsum sagittis id. Vivamus imperdiet erat at enim vulputate lacinia. Praesent consectetur efficitur congue. Suspendisse eget tincidunt ipsum. Curabitur eget viverra odio, eget tempus justo. In hac habitasse platea dictumst. Phasellus efficitur egestas mauris, quis feugiat ex rhoncus vitae. In iaculis eleifend diam et accumsan. Praesent hendrerit risus quam, nec mattis quam lobortis at. Fusce massa mi, ultrices et dui nec, semper efficitur sem.

Donec laoreet tellus nisl, eu aliquet velit porta sit amet. Nunc convallis, leo vel tristique dictum, nisi nisl placerat enim, placerat semper tellus mi id erat. Phasellus ipsum mauris, lobortis quis nunc ac, maximus efficitur eros. Aenean vitae ante fringilla, suscipit ante sit amet, congue dolor. Interdum et malesuada fames ac ante ipsum primis in faucibus. Praesent justo mauris, viverra ac ante a, fringilla convallis nulla. Praesent rhoncus sapien in blandit porttitor. Duis vel scelerisque urna. Quisque sed laoreet leo.

Cras ante enim, venenatis placerat ullamcorper id, posuere ut sem. Nulla lobortis lacus at nisi mollis, sed fringilla est porta. In vel venenatis leo, non rutrum nibh. Vestibulum venenatis dolor mauris, at sagittis purus gravida nec. Curabitur in ligula eu erat porttitor maximus. In eget nunc quis enim blandit porttitor ut vel lorem. Proin tortor ante, accumsan eget pretium quis, tincidunt sed felis. Nam quis finibus leo. Cras sollicitudin arcu dui, ultrices blandit erat porta quis. Quisque finibus sodales augue porttitor consectetur. Sed aliquam ante leo, vitae pharetra nulla tempus eget. Proin eu odio velit. In ac lacus non purus rutrum elementum id sit amet orci. Vestibulum nulla arcu, vehicula non tortor sit amet, venenatis posuere neque.

Fusce pretium eros ac nisl lobortis, semper elementum enim sollicitudin. Duis ligula ex, interdum et feugiat sed, tempor vel urna. Nam id quam sed arcu rhoncus tempor. Quisque sodales ligula ac odio pulvinar, ac posuere quam egestas. Aenean hendrerit elementum pulvinar. Nunc laoreet sagittis urna sit amet euismod. Ut id neque ante. Sed tincidunt orci ullamcorper dui malesuada, at pharetra magna posuere. Morbi vitae luctus leo. Lorem ipsum dolor sit amet, consectetur adipiscing elit.

Aliquam nec erat eu nisi egestas interdum. Mauris eleifend eros sit amet fermentum pulvinar. In mollis faucibus est finibus varius. In vitae nisl non sapien malesuada pretium. Nulla volutpat elementum suscipit. Mauris blandit ligula nec mi vehicula aliquam. Suspendisse molestie rutrum urna, gravida efficitur nisl eleifend vel. Pellentesque in mauris a tellus pretium suscipit. Donec pharetra ligula mollis elit maximus sagittis. Cras viverra elit quis nisi cursus, at luctus velit aliquam. Nunc iaculis lorem ut velit maximus placerat. Phasellus a purus lectus. Vestibulum imperdiet, turpis ut tincidunt feugiat, lacus eros congue felis, ac pellentesque urna ex ac erat. Nam blandit rutrum felis, id hendrerit turpis pulvinar in. Suspendisse semper ex id leo porttitor vehicula. Nunc ut neque tristique mi suscipit finibus eget in nisi.

Curabitur pellentesque metus quis odio efficitur venenatis. Integer efficitur lectus posuere pharetra vestibulum. Nulla enim eros, hendrerit vitae metus vel, facilisis egestas mi. Aenean pellentesque, massa quis pretium commodo, diam augue blandit turpis, ac pretium felis massa ut augue. Sed sed leo tempor, commodo quam vitae, consequat nulla. Nullam id orci purus. Donec ultricies, leo condimentum dignissim mattis, ante elit auctor odio, in tempus sem ante sed sem.

Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. In maximus urna urna, et varius tellus elementum vel. Ut pellentesque cursus gravida. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Etiam rutrum vel magna at dapibus. Morbi vel ex erat. Integer vehicula vehicula justo, ut auctor libero rhoncus eget. Sed ac lorem nec sapien gravida dictum non ac sem. Praesent vitae elit sodales, efficitur felis et, faucibus nunc. Praesent iaculis tincidunt magna, vitae semper turpis pharetra in. Donec lacus tellus, tincidunt iaculis scelerisque sed, laoreet malesuada enim. Donec sollicitudin viverra felis at condimentum. Nunc tincidunt, turpis quis congue dignissim, sem nunc vulputate dui, vel pellentesque nibh nunc eu diam. Integer urna quam, posuere nec dolor et, faucibus imperdiet nulla. Nunc nibh sem, eleifend vel convallis vel, pretium non metus. Vestibulum molestie tincidunt arcu, ac ullamcorper eros mattis a.

Vivamus mauris elit, hendrerit eu arcu suscipit, fringilla porta neque. Integer pharetra egestas gravida. Vestibulum condimentum quam non leo pellentesque, vitae hendrerit turpis fermentum. Sed et placerat sapien, eu dignissim turpis. Fusce in neque tristique velit finibus auctor quis malesuada lectus. In rhoncus pharetra dolor eu tempor. Nunc dictum dolor laoreet, facilisis eros vel, rhoncus elit. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Suspendisse nec blandit felis. Pellentesque sed dictum leo. Quisque nec risus quam.

Quisque vel orci augue. Phasellus mollis vitae velit ut ultrices. Aliquam nec odio ut velit feugiat auctor. Cras tempus viverra leo ac pretium. Cras molestie felis in vehicula tincidunt. Sed dictum, magna non lobortis bibendum, diam nibh porttitor risus, ut hendrerit orci velit pulvinar ex. Vivamus porta ac lectus ut bibendum. Sed maximus congue pharetra. Praesent turpis magna, placerat nec risus pharetra, viverra faucibus magna. Ut et efficitur nunc. In hac habitasse platea dictumst. Ut auctor et eros ac consectetur. Sed eu fringilla nibh.

Mauris sodales velit magna, et placerat mi imperdiet ac. Fusce auctor orci nec mi pharetra, et dictum est porttitor. Nunc lacinia neque at justo aliquam, eu interdum sapien molestie. Aliquam ut lobortis nisi, sit amet pretium tortor. Cras et convallis justo, sed tempor nulla. Fusce pulvinar orci non libero mollis aliquet. Nullam molestie elementum mauris, at dapibus nisi auctor ac. Donec in blandit quam. Aenean non odio tristique, mattis diam vitae, dictum nunc.

Aliquam ut semper risus. Phasellus euismod elit id orci semper scelerisque. Ut vel mi ut dui dictum tincidunt. Proin porttitor nunc augue, vitae imperdiet metus cursus sed. Morbi nisl leo, semper quis enim pulvinar, mollis efficitur enim. Vivamus tincidunt scelerisque metus, aliquam condimentum tortor tincidunt sed. Aliquam commodo et odio vitae ultricies. Morbi ultrices urna in nisl bibendum rutrum. Donec rhoncus ipsum vitae interdum consequat.

Nulla lacinia massa sed ex scelerisque facilisis. In hac habitasse platea dictumst. Etiam eget dictum massa. Aliquam hendrerit libero sem, non efficitur sem tincidunt et. Suspendisse sed faucibus eros. Aenean finibus mattis libero quis dapibus. Mauris sed tempor justo. Ut egestas odio in lacinia convallis. Proin porta nisl imperdiet pretium tempor. Cras sed eros nec quam pellentesque faucibus.

Morbi tortor velit, volutpat non fringilla a, sagittis ac libero. Aenean consequat maximus ipsum et commodo. Vestibulum pulvinar est eu augue hendrerit, id bibendum quam elementum. Curabitur nibh sapien, consectetur eget placerat nec, scelerisque a quam. Quisque semper dapibus nunc eu blandit. Ut et lectus tellus. Ut nec ultrices lorem. Donec convallis sapien eros, at bibendum felis molestie et. Phasellus at nisl vitae est fermentum pharetra sed id ligula. Donec commodo nisi id neque mattis rhoncus.

Mauris dolor nisi, elementum vel tortor non, tempus placerat ipsum. Maecenas ultricies tortor dui, eu efficitur dui sollicitudin at. Duis semper, nisi non ornare luctus, libero metus vulputate nisl, ut vestibulum enim nulla sit amet elit. Pellentesque malesuada ligula diam, non tristique velit vestibulum eu. Sed id imperdiet turpis. Quisque suscipit nunc leo, quis placerat turpis lacinia a. Interdum et malesuada fames ac ante ipsum primis in faucibus. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Ut venenatis nunc lectus. Phasellus accumsan consectetur lacinia. Fusce ornare ipsum erat, a interdum lorem semper et. Sed efficitur diam ipsum. Cras eget consequat felis. Nullam dapibus orci urna, ut dapibus lectus gravida at. Aliquam mauris massa, mollis in rhoncus quis, euismod pulvinar purus.

Sed ac nisi malesuada, vestibulum leo eget, rutrum est. Fusce sapien nibh, sagittis accumsan justo ac, tincidunt scelerisque velit. In ornare metus tincidunt volutpat porta. Nunc fermentum quis est in iaculis. Duis auctor non nulla ut blandit. Maecenas nec felis nec sem tincidunt aliquam nec sed diam. Duis dapibus mauris non felis pretium, et commodo ipsum venenatis. Cras imperdiet condimentum diam.

Praesent ultrices quam tellus. Proin quis lacus vitae ligula rutrum semper non vel felis. Nulla at mauris id eros tempus interdum nec eu ipsum. Vestibulum tincidunt facilisis sapien ac dignissim. Sed eget lectus elit. Ut auctor luctus felis, vel viverra libero finibus at. Nullam a faucibus nisl. Fusce mollis eu ante ut hendrerit.

Quisque a sem ultricies, volutpat felis vitae, tincidunt justo. Suspendisse elementum tempus mi, ac imperdiet velit convallis sit amet. Vestibulum condimentum congue elit, a faucibus nisi consequat quis. Nulla vehicula rutrum sem a dapibus. Aliquam egestas sed nisi eget condimentum. Proin nunc tellus, imperdiet vitae eleifend ut, elementum eget quam. Pellentesque lorem lorem, tempus nec suscipit finibus, congue eu purus. Donec sagittis semper enim, ut eleifend arcu vehicula quis. Sed ornare nibh purus, vitae volutpat sapien lacinia id. Pellentesque leo elit, aliquam et vulputate id, efficitur ac enim. In hac habitasse platea dictumst.

Nunc a diam congue, pretium lacus sit amet, sollicitudin velit. Pellentesque efficitur augue maximus nunc convallis consectetur. Suspendisse eu lorem enim. Donec eget sapien congue, elementum arcu ut, vulputate lectus. Suspendisse ut sagittis dolor. Ut magna magna, tempus non pretium sit amet, bibendum sit amet diam. Nullam porttitor auctor fermentum. Cras efficitur posuere ultrices.

Nulla urna mauris, luctus et bibendum in, cursus sit amet odio. Cras egestas pretium velit. Aenean consectetur porttitor tellus, quis tincidunt purus iaculis eu. Sed nisl metus, feugiat id dapibus sed, pretium consequat elit. Nulla efficitur vehicula mollis. Maecenas placerat lorem erat, nec porta massa tristique in. In hac habitasse platea dictumst. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos.

Vivamus non feugiat leo. Vivamus ornare porttitor arcu, sit amet suscipit magna varius ut. Curabitur a rhoncus augue. Aenean maximus scelerisque quam, eu tempus ex facilisis in. Morbi eu justo eget orci suscipit dapibus at sit amet justo. Cras at purus sagittis, auctor ante sit amet, condimentum massa. Sed elit orci, convallis nec viverra eget, convallis vel risus. Praesent venenatis enim sed nunc semper posuere. Sed vitae pretium velit. Integer nec justo vel nisl rhoncus finibus. Phasellus ornare, nunc id maximus blandit, magna nunc ultrices ex, at sollicitudin nibh nisl eget justo.

Integer quis sapien a nisl aliquam hendrerit. Duis lorem est, pulvinar sit amet augue et, finibus commodo quam. Vivamus convallis ex id dolor rhoncus fermentum. Suspendisse ut congue quam. Etiam a quam id enim cursus dapibus. Donec eget vestibulum metus, eu tincidunt purus. Vivamus et placerat tellus. Aliquam a interdum orci.

Donec varius leo eu est sagittis ultricies. Sed metus sem, viverra dignissim sagittis sed, pretium a nunc. In sollicitudin nisi ut elementum vestibulum. Vivamus non purus molestie, sollicitudin mauris nec, ullamcorper orci. Curabitur vitae mi vel lacus sollicitudin elementum et sit amet massa. Curabitur placerat luctus cursus. Donec et tellus tortor. Etiam blandit, lorem vel maximus hendrerit, enim lacus vehicula mi, sit amet accumsan libero mi nec diam.

Curabitur bibendum augue at lacus porttitor, et volutpat lacus tincidunt. Aliquam blandit vehicula ultrices. Vestibulum ultrices est sed risus ullamcorper, et elementum ante faucibus. Pellentesque porta urna velit, sed aliquam justo tristique quis. Integer hendrerit, quam non gravida aliquet, diam orci commodo nunc, vitae gravida ipsum dui a est. Vestibulum justo est, lobortis sed efficitur non, ullamcorper sit amet ligula. Nunc non lectus tellus. Praesent accumsan nec nisi ut fringilla. Quisque et urna aliquet, tempus purus sit amet, tempor magna.

Vivamus egestas aliquet urna vel feugiat. Integer diam elit, auctor vitae mollis at, lacinia ut purus. Suspendisse consectetur sollicitudin magna, eget gravida massa venenatis sit amet. Quisque ac accumsan velit, pulvinar varius mauris. Nunc sodales at odio vitae sagittis. Suspendisse ac porttitor orci. Etiam nec eros molestie, vehicula erat sed, aliquam ex. Nulla in condimentum eros, vestibulum porttitor nisl. Vivamus efficitur ultricies nibh, eu eleifend ligula pharetra eu. Praesent eget sem nec orci volutpat sodales non et orci. Quisque eu aliquet eros. In hac habitasse platea dictumst. Duis egestas sagittis aliquet. Etiam malesuada elementum urna, ut euismod est interdum vitae.

Maecenas elementum leo sit amet lobortis aliquet. Curabitur arcu mauris, consequat eu suscipit id, venenatis id erat. Curabitur egestas, nulla eget finibus scelerisque, risus mi sollicitudin urna, a convallis purus leo sit amet ante. Curabitur facilisis finibus condimentum. Quisque vel dui sit amet enim aliquet cursus. Proin feugiat finibus erat, nec pulvinar mauris feugiat sit amet. Maecenas faucibus efficitur lectus, eu interdum lorem volutpat eget.

Praesent facilisis erat iaculis metus auctor, sed dignissim nisi molestie. Praesent mauris quam, venenatis id congue imperdiet, euismod quis velit. Maecenas id mauris purus. Integer ornare leo elit, eu luctus ipsum rutrum sed. Sed ut tincidunt urna. Sed aliquam pellentesque turpis, eu tristique orci dictum in. Duis ultrices nisl at vehicula blandit. Nullam sagittis ullamcorper tellus, id interdum velit faucibus eu. Vivamus augue augue, vestibulum vehicula mauris a, sollicitudin feugiat lorem. Maecenas et maximus neque. Proin molestie eleifend ex sed cursus. Quisque eget erat finibus, dapibus sem ultrices, ornare lacus. Phasellus ut blandit lorem. In auctor, lectus sed malesuada fermentum, nibh ante pulvinar ante, a egestas elit dui eget metus. Cras non efficitur nisi. Nam eget ex ut turpis dictum vehicula.

Donec quis efficitur neque. Phasellus sed facilisis dui. Sed commodo, risus sit amet vehicula fermentum, orci purus venenatis metus, a molestie nisi risus vel ligula. Integer at quam non nisl vehicula aliquet quis id purus. In tincidunt auctor lacus vel blandit. Suspendisse odio est, luctus sed tincidunt at, dictum quis nibh. Nulla iaculis ipsum nec velit commodo iaculis at sed nunc. Nam iaculis egestas lacus, a consectetur felis congue id. Cras ac est elementum, luctus nunc eu, aliquam odio.

Nunc quis nunc rhoncus, bibendum ligula ut, finibus tortor. Nunc facilisis magna sed purus auctor, hendrerit aliquam nunc dignissim. Mauris magna felis, imperdiet interdum malesuada at, euismod vitae ante. Curabitur condimentum bibendum urna sit amet accumsan. Aenean sit amet aliquet velit. Mauris aliquam imperdiet eros, non lacinia nisl facilisis sodales. Mauris faucibus at nibh a sagittis. Curabitur a eros nisi. Interdum et malesuada fames ac ante ipsum primis in faucibus. Aliquam sagittis, metus quis malesuada imperdiet, metus risus feugiat enim, sed tempor neque enim quis ligula. Vestibulum consequat vestibulum lectus ac sodales. Nam convallis sed libero id placerat.

Maecenas interdum dui id ornare efficitur. Duis pulvinar nunc nec turpis feugiat, a tempor nunc sagittis. Mauris rutrum quam sit amet sem faucibus ullamcorper. Aenean vel nulla vitae tellus rhoncus blandit sit amet aliquet enim. Quisque sit amet mattis eros, vitae commodo velit. Curabitur at pulvinar lacus. Fusce tristique blandit nisl in finibus. Praesent at enim libero. Etiam ac imperdiet purus, non malesuada justo. Duis ut massa ut sapien tempus lacinia eget eu quam. Donec sapien ante, accumsan non mollis ac, imperdiet varius magna. Suspendisse quis fermentum purus. In pulvinar, lacus eget euismod hendrerit, nibh neque bibendum odio, in pulvinar justo sapien a tellus. Integer a diam bibendum, aliquam mi a, iaculis risus.

Praesent rhoncus nec ipsum et suscipit. Cras velit neque, pharetra quis nibh eget, cursus facilisis augue. Proin ac placerat est. Vivamus leo ligula, lobortis et ligula et, efficitur efficitur lorem. In fringilla elit eget metus rhoncus rutrum. Sed tempus condimentum fringilla. Suspendisse nulla ante, rhoncus ac nisl vitae, sagittis tempus odio. Suspendisse potenti.

Cras dictum faucibus pulvinar. Vivamus quam diam, iaculis in porttitor at, mattis in orci. Pellentesque dignissim sapien non erat fringilla laoreet. Etiam volutpat, ante venenatis faucibus ultricies, odio risus hendrerit purus, at porta est mauris sed lorem. Aliquam pharetra dolor et massa tincidunt, in dictum lectus fringilla. Suspendisse lectus magna, fringilla sed augue volutpat, commodo convallis purus. Phasellus hendrerit magna elit, sed consequat nulla accumsan id. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec eget tincidunt purus. Sed tempor lectus non hendrerit molestie.

Quisque non diam suscipit, ornare nunc sit amet, placerat neque. Donec molestie quis orci nec consectetur. Sed eget tincidunt urna, id porta tellus. Praesent ac sapien nec nisl tincidunt tempor id eget lorem. Praesent quam erat, varius ut diam quis, ullamcorper vulputate urna. Mauris congue elit in tincidunt imperdiet. Mauris turpis velit, venenatis non egestas et, elementum ac nulla. Aenean leo erat, vestibulum vitae erat sit amet, imperdiet sodales tellus. Nam sodales ornare mauris eget consequat. Nullam vel magna vitae ipsum auctor consectetur nec at tellus. Aliquam bibendum arcu nibh, ut cursus erat finibus quis. Nulla laoreet felis sapien, id pellentesque elit volutpat ac. Curabitur at blandit eros. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus.

Nunc vel interdum velit. Aliquam ipsum odio, scelerisque venenatis tincidunt ultrices, gravida a massa. Aenean sed luctus est, ut egestas arcu. Quisque dapibus magna ut nibh suscipit, nec posuere ipsum volutpat. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Nullam neque nisl, volutpat eget sodales id, vehicula eget ipsum. Sed suscipit leo ac pretium mattis. Nam ac arcu at lectus interdum elementum nec vel augue. Aliquam varius velit arcu, eget sodales libero rhoncus id. Proin sit amet neque mollis, pulvinar quam sit amet, efficitur sem. Cras auctor porttitor eros at dictum. Aenean blandit erat in dui dapibus, sit amet lobortis diam pulvinar. Donec pharetra at mi finibus fringilla. Cras eu metus bibendum diam scelerisque porttitor sed eu velit. Integer vitae quam lorem. Aliquam mollis ante vitae nulla sollicitudin dapibus.

Maecenas vitae purus eget nunc convallis ultrices. Nunc interdum lectus non tincidunt rhoncus. Praesent enim erat, malesuada a venenatis ut, dapibus quis justo. Donec quis porttitor elit, vitae pharetra mauris. Fusce elementum, sapien ac condimentum venenatis, mauris purus congue justo, in malesuada dolor diam ut metus. Nulla id nunc velit. Cras sed lacinia velit, sit amet feugiat quam. Duis commodo mollis turpis, eget gravida nisl suscipit et. Pellentesque nec erat lacus. Donec sed dictum neque.

Curabitur eu sem sed ipsum interdum aliquet sit amet et nulla. Integer lobortis nisi quis massa dictum blandit. Etiam eget ligula dui. Mauris lacinia, urna quis eleifend consequat, lacus purus pulvinar ipsum, eget fringilla magna purus vitae tortor. Nullam finibus, dolor lacinia suscipit congue, metus nisi fringilla justo, nec ultrices lacus ante dapibus sapien. Morbi eros nibh, tempus quis tempus et, cursus in mauris. Nullam dignissim sapien sit amet urna consequat, ac porta massa finibus. Nullam imperdiet egestas sem vitae blandit. Sed in felis eu ante posuere consequat et non justo. Aenean consectetur, felis viverra interdum dignissim, elit leo pharetra ipsum, quis semper diam tellus eu ex. Mauris accumsan odio sit amet eros lobortis volutpat. Mauris lacinia convallis enim, placerat porta mi molestie ut.

Donec ultricies volutpat neque, at ultricies mi ultricies nec. Morbi eget nisi viverra ex rhoncus tempor. Aenean maximus eleifend libero sit amet hendrerit. Aliquam ut ligula at ante interdum blandit eu vitae arcu. Praesent ut tortor ex. Maecenas eget ante ut elit ornare elementum sodales sit amet lorem. Maecenas hendrerit nisi eu urna porta, ac facilisis justo varius. Nulla sem tortor, fermentum vel volutpat eget, posuere a diam. Praesent congue magna at bibendum placerat. Etiam at dolor mollis, ultrices libero at, consectetur urna.

Fusce risus turpis, euismod eu consequat vitae, malesuada non lectus. Fusce purus ex, venenatis sed dolor in, consectetur mollis quam. Curabitur vitae malesuada libero, a semper lacus. Fusce sodales quis ex in faucibus. Aliquam venenatis dapibus sapien a tincidunt. Duis quis ipsum rutrum, tempus velit in, congue mauris. Vestibulum non risus lectus. Quisque sem ex, iaculis ac aliquam non, semper sit amet nibh. Maecenas finibus auctor egestas. Sed vitae dolor quis sapien dapibus consequat sed ac velit. Vivamus laoreet rhoncus enim a tincidunt.

Nullam auctor, nisl et eleifend scelerisque, augue turpis facilisis ipsum, vel viverra tellus turpis quis sapien. Fusce viverra purus sed ipsum lobortis vestibulum. Nullam et tortor pulvinar, varius nisi ut, egestas justo. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae; Praesent euismod, turpis a volutpat molestie, ipsum sem commodo purus, eget auctor elit eros sed quam. Nam eu libero ac tellus vehicula feugiat non eu tortor. Nam et aliquam lacus.

Nam tincidunt ligula at accumsan consequat. Donec vulputate justo eu purus finibus molestie. Quisque accumsan ex velit, at iaculis eros venenatis in. Nam placerat, dolor id maximus vulputate, lectus sem ullamcorper neque, non blandit elit diam eget sem. Etiam placerat eu augue in pellentesque. Duis sit amet nulla sit amet erat volutpat vestibulum consectetur vel ex. Nulla nec purus iaculis, dapibus sapien vel, aliquet turpis. Pellentesque suscipit dictum eros. Duis bibendum rhoncus nibh sit amet bibendum. Mauris imperdiet interdum ullamcorper. Mauris sodales pulvinar magna sit amet facilisis. Duis sit amet mauris nec libero fringilla interdum.

Quisque quis enim nec eros interdum egestas. Donec et mauris et leo cursus egestas. Proin viverra sit amet sapien sit amet interdum. Etiam congue odio nec ipsum lobortis lobortis. Nam feugiat viverra odio nec fermentum. Nunc eu fermentum nulla, in sollicitudin neque. Aliquam faucibus lacinia lacinia. Nunc varius, turpis eu molestie vulputate, lacus lectus venenatis lorem, quis faucibus ante enim eu velit. Integer ac sagittis quam. Nullam at placerat elit. In ornare fringilla enim vel consequat. Duis accumsan pulvinar enim, at consectetur leo pretium non.

Nullam pretium pellentesque lorem aliquam convallis. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec eleifend metus eget ipsum eleifend, a molestie diam tempus. Nam ornare, nibh et convallis aliquam, nunc risus fringilla lacus, sed commodo nibh felis sed risus. Proin aliquam fringilla metus. Nullam vehicula lobortis convallis. Vivamus varius augue a sem vehicula dapibus. Cras non rhoncus dolor, et porta neque. Integer risus ex, porta a neque sit amet, facilisis aliquet arcu. Nullam ultrices finibus nulla faucibus rutrum. Morbi pretium commodo felis. Vestibulum non diam scelerisque, auctor dolor consequat, scelerisque nisl. Proin faucibus massa vel metus sagittis imperdiet. Phasellus congue libero lacus. Etiam orci quam, bibendum sit amet aliquam at, venenatis ac lectus.

Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Aenean facilisis vel neque quis mollis. Aliquam id metus maximus, facilisis felis et, venenatis elit. Praesent bibendum orci a sodales rutrum. Aliquam erat volutpat. Aliquam luctus convallis dictum. Pellentesque condimentum turpis nisl, ac aliquet lorem gravida non. Etiam sit amet lacus id velit varius convallis sit amet at est. Nam turpis dolor, faucibus sit amet rhoncus nec, consequat sit amet quam. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Vivamus porta ipsum non mollis tempus. Suspendisse potenti. Curabitur faucibus purus a risus maximus euismod. Nulla in sollicitudin dui. Duis maximus dolor ornare euismod varius. Morbi at mi vestibulum, suscipit orci at, euismod purus.

Integer efficitur elit id velit dignissim vehicula. Vestibulum ultricies arcu at lorem posuere, vitae eleifend felis blandit. Curabitur consectetur, lacus at feugiat blandit, enim nulla accumsan purus, sed efficitur lectus neque porttitor dui. Quisque porttitor auctor cursus. In facilisis ut dolor condimentum rutrum. Maecenas consectetur euismod dui et congue. Donec sed lorem tellus. Phasellus sed erat quis ipsum gravida convallis faucibus id mi. Sed sagittis laoreet egestas. Integer vitae orci ante.

Pellentesque nulla ligula, tempus eu lacus vel, blandit rutrum quam. Vestibulum et efficitur urna, accumsan aliquam neque. Phasellus blandit arcu in dolor facilisis, vel imperdiet odio ultrices. Aenean leo elit, dictum sed ullamcorper quis, consectetur ac lacus. Etiam tincidunt euismod aliquam. Pellentesque vel nunc lobortis, suscipit nunc sit amet, volutpat erat. Duis facilisis lacus aliquam dolor aliquet semper. Morbi ac nunc dui. Donec feugiat ultricies dolor eget euismod. Nam vel hendrerit nunc. Sed augue eros, rhoncus in pharetra vitae, interdum ut ante. Ut posuere risus vitae diam mollis ornare. Donec consectetur lobortis leo in auctor. Nullam facilisis egestas felis ac viverra.

Praesent lacinia sollicitudin dapibus. Suspendisse ac posuere nibh. Aliquam erat volutpat. Aliquam erat volutpat. Ut sed metus id nisl tempus feugiat. Phasellus feugiat vehicula tortor, sit amet tincidunt lacus blandit vel. Duis vulputate quam ac pulvinar consectetur. Proin suscipit cursus velit, vitae condimentum sapien molestie vitae.

Ut id vehicula urna, id aliquet quam. Cras scelerisque magna nulla, eget fermentum ipsum molestie at. Aliquam fermentum quis ante eget sollicitudin. Sed ante eros, luctus non nisl eu, pretium suscipit mauris. Etiam velit elit, tempor non ipsum et, cursus auctor nunc. Pellentesque ut eleifend tellus. Donec feugiat erat ante, ut semper quam luctus vitae. Suspendisse dignissim, lorem id tincidunt auctor, libero lorem porta nulla, eu rutrum felis risus ut leo. Nunc congue, massa nec placerat tincidunt, felis risus auctor mi, ac luctus orci sem a mi. Donec bibendum velit ipsum, vel consectetur mi fermentum eget. Aenean cursus feugiat magna id mollis. Suspendisse vulputate scelerisque purus, facilisis eleifend dolor ultricies a. Vivamus elementum mi eu risus efficitur viverra. Vivamus malesuada risus nibh, id ullamcorper ipsum viverra a.

Duis et felis dolor. Nullam ultricies fermentum ipsum eu finibus. Aliquam ligula nunc, auctor malesuada volutpat auctor, iaculis a purus. Donec id mattis purus. In sed odio id ante lacinia ultrices. Cras elementum mattis leo, nec molestie ligula vestibulum bibendum. Mauris mi ipsum, sollicitudin ac ornare at, mattis a leo. Suspendisse potenti. Cras commodo pharetra libero nec interdum. Praesent molestie gravida arcu ac dictum. Nulla facilisi.

Morbi quis ipsum vel felis sollicitudin scelerisque. Fusce tempus, quam mollis consequat cursus, mi orci lacinia ipsum, consequat rhoncus est nulla a ex. Curabitur condimentum dapibus accumsan. Vestibulum egestas consequat sodales. Curabitur eu nulla lacinia, ornare risus vel, convallis felis. Nunc commodo maximus volutpat. In eget euismod turpis, vel rhoncus ligula. Nullam in elit in tellus vehicula convallis at ac elit. Etiam mollis nisl at elit tempus, vel dignissim elit ullamcorper. Sed sollicitudin rhoncus libero non finibus. Nullam convallis orci purus, vitae elementum elit ullamcorper in.

Fusce eu lorem id ligula finibus tempor eu nec purus. Cras elementum fringilla turpis vel pellentesque. Cras in lacinia tellus, sed tristique mi. Fusce vitae elit nec metus interdum consequat ac a lacus. Sed vestibulum velit magna, at posuere tellus lacinia ac. Nullam sit amet ex pellentesque, lacinia felis nec, tristique quam. Aenean in justo nec tortor sodales mollis nec vitae nunc. Suspendisse commodo, mi ut fermentum molestie, erat turpis interdum sem, at faucibus quam neque pellentesque est. Sed consequat vestibulum purus non elementum. Donec fringilla nunc et dui posuere, eu dictum neque ultrices. Quisque pretium orci sapien, sed venenatis quam tempor at. Nulla rutrum erat ex. Maecenas urna nibh, bibendum et dui eu, auctor semper lectus. Donec varius tincidunt lorem non hendrerit. Donec nec magna eleifend, cursus dui sodales, pharetra nunc.

Maecenas lectus metus, dapibus egestas purus quis, porttitor sollicitudin magna. Curabitur laoreet convallis orci, quis laoreet ipsum euismod quis. Suspendisse rhoncus neque eget sem finibus, ac finibus lacus egestas. In consectetur molestie lectus in imperdiet. Praesent consequat orci ut nisi eleifend hendrerit. Fusce sed egestas magna. Praesent ut erat quis neque volutpat rutrum ac sed tellus. Suspendisse potenti. Curabitur sit amet porttitor lorem, at ultrices est.

Cras eget fermentum ex. Suspendisse a mauris in ipsum tincidunt rhoncus. Pellentesque sed turpis ac dolor dignissim egestas sed a turpis. Nunc pretium congue gravida. Vestibulum posuere suscipit nulla, sed lobortis dolor. Nulla sed sapien in justo auctor condimentum. Donec laoreet pharetra elit, at efficitur ligula tempus at. Sed luctus dui ac nibh placerat, a sollicitudin sem imperdiet. Donec pretium sapien ac erat pulvinar rhoncus. Etiam in velit pulvinar dolor ultricies finibus. Aliquam ut nibh tellus. Proin faucibus pulvinar ex vitae dignissim. Integer hendrerit eros id mi fermentum rutrum. Etiam posuere consectetur ante, ac tincidunt justo auctor sit amet. Aliquam et mattis metus.

Vivamus semper varius leo, ac lacinia lectus eleifend et. Sed blandit euismod risus, vitae ullamcorper lacus lacinia varius. Donec et faucibus dui, ac ultrices metus. In a libero libero. Aliquam molestie, lorem nec efficitur ornare, sem metus malesuada massa, eget cursus urna lacus et quam. Etiam id nunc tempor, fermentum odio vel, sagittis magna. Proin auctor, orci venenatis faucibus tempor, mauris diam blandit nulla, mattis tincidunt lorem eros nec libero. Sed feugiat bibendum ultrices.

Suspendisse massa dui, tempor et mauris nec, venenatis bibendum ipsum. Sed egestas tempus iaculis. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Mauris pharetra, dui vel hendrerit varius, dolor dolor lobortis libero, at porttitor nibh ex quis tortor. Vivamus sed nisi at justo egestas blandit. Sed et ipsum dolor. Maecenas sollicitudin eros eget diam tempus, et fringilla erat gravida. Nullam tincidunt enim sed sollicitudin suscipit. Nulla facilisi.

Integer sagittis dolor facilisis, pretium metus vitae, eleifend magna. Donec quis tempus arcu, eget mattis eros. Pellentesque gravida sagittis erat, eget euismod turpis hendrerit non. Ut aliquet bibendum feugiat. Nam dapibus laoreet justo sit amet euismod. Integer dapibus eros et diam mollis, non posuere libero placerat. Nam at ligula mollis, semper nisi nec, bibendum ante. Aliquam condimentum lorem sit amet eros pharetra, a varius ante euismod. Mauris volutpat odio a tortor viverra commodo. Phasellus ut libero ornare, aliquet leo in, condimentum eros. Vestibulum arcu risus, tristique vel tempor id, blandit nec nunc. Vivamus ante orci, tempus eu mauris vel, convallis interdum elit. Integer eu magna vel ligula auctor molestie.

Quisque eu aliquet massa. Fusce porttitor vitae lectus eu sollicitudin. Quisque a pretium massa. Donec congue, nisi et efficitur rhoncus, mi est ultricies dolor, maximus elementum orci justo sit amet tellus. Etiam placerat blandit ligula, sed consequat sem porttitor non. Duis quam nisl, convallis quis posuere id, accumsan venenatis velit. Integer feugiat aliquam neque, vitae imperdiet nulla. Sed posuere sed metus nec venenatis. Proin leo est, eleifend vitae sagittis eu, dictum et eros. Nullam eleifend eget nulla luctus elementum. Nulla facilisis vitae dui non tincidunt. Nam odio libero, dapibus et facilisis vitae, lacinia sit amet eros. Donec vel dapibus nibh.

In pretium maximus ex, quis ultrices purus finibus sed. Nunc laoreet turpis vitae ullamcorper maximus. Vestibulum pellentesque enim vitae eros lacinia, vel porta augue tincidunt. Maecenas quis sapien congue, auctor risus sed, eleifend libero. Ut mollis vitae mauris ut porta. Phasellus magna arcu, luctus ut ultrices non, euismod id magna. Mauris ut turpis vel urna mollis suscipit. Ut at justo vitae sem convallis malesuada. Sed a dapibus lorem. Donec et lacus tempor, dignissim sapien id, accumsan dui. Ut ac sem quis orci vulputate fringilla. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas.

Morbi aliquam tellus facilisis interdum tincidunt. Praesent cursus ornare eros, a vehicula odio tempus in. Fusce quis suscipit elit, viverra semper risus. Sed enim nisl, consequat sed consequat ut, mattis a tellus. Ut auctor, lectus sed pretium egestas, neque nisi tristique tortor, vel viverra odio ligula a turpis. Nullam sodales euismod vehicula. Duis volutpat, nibh pharetra efficitur elementum, odio orci faucibus lacus, eu maximus orci tellus at eros. Duis eleifend, neque eu maximus ultricies, libero sapien facilisis turpis, quis dictum leo lorem quis nisi. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Vivamus sit amet gravida sapien. Donec scelerisque tempus egestas.

Nulla auctor eleifend nisl, in pharetra elit pharetra quis. Nulla iaculis metus a felis volutpat sodales. Sed at facilisis sem. Etiam in magna scelerisque, mattis augue nec, egestas risus. Quisque lacinia tempus erat sed rhoncus. Sed facilisis turpis mauris, sit amet rhoncus erat tincidunt nec. Etiam scelerisque erat nisi, vel consequat nibh cursus in. Nunc semper sapien et lacus ornare rutrum nec quis mauris. Praesent lorem nunc, feugiat a neque quis, ultricies congue urna. Donec sed tincidunt neque.

Sed eu consequat ligula. Mauris rutrum tellus tortor, eget venenatis turpis ullamcorper eget. Curabitur nisl diam, suscipit non facilisis vel, blandit eget enim. In vitae massa risus. Aliquam vehicula, lacus at volutpat facilisis, justo lectus elementum elit, consequat feugiat mi dui sit amet massa. Quisque ornare sem ac lectus aliquet condimentum. Duis laoreet, nisl non finibus mattis, dui dui ultricies erat, nec tempus augue turpis eu tortor. Integer leo enim, maximus quis metus sed, auctor pulvinar lorem. Mauris dictum neque a tempus mollis.

Suspendisse malesuada sed felis nec accumsan. Sed sit amet augue iaculis nibh pellentesque finibus vitae eu ligula. Sed nisi risus, tempor ac dolor eget, tincidunt tincidunt eros. Integer finibus pharetra lectus sit amet cursus. In metus ipsum, egestas vitae mollis non, ullamcorper eget urna. Duis feugiat turpis ut sem volutpat, non egestas quam posuere. Proin at sagittis est, sit amet pretium est. Donec vel augue gravida, congue sapien at, euismod mauris. Proin arcu turpis, ullamcorper vitae maximus nec, placerat eu erat. Morbi euismod aliquet orci porttitor aliquam. Integer venenatis arcu at justo pellentesque, in fermentum lectus imperdiet. Curabitur rutrum, sem in cursus auctor, justo dui aliquam mauris, vitae ultrices risus ex nec enim.

Donec congue gravida gravida. Etiam sollicitudin venenatis nunc eu faucibus. Nam pharetra volutpat sem, non facilisis nibh tempus hendrerit. Mauris tempus venenatis nisi sit amet egestas. Donec vestibulum laoreet purus ac dignissim. Phasellus aliquam magna vel vehicula bibendum. Fusce egestas tristique dolor, nec dictum augue scelerisque et. Vivamus in metus ex. Suspendisse maximus purus est, nec vestibulum lectus aliquet sit amet. In viverra suscipit posuere. Pellentesque nec magna in sem commodo egestas. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae;

Pellentesque ultrices tortor lacus, eu lobortis metus mattis quis. Mauris vel aliquam lorem, eu placerat nunc. Mauris enim dui, lobortis quis iaculis id, interdum vel quam. Phasellus consectetur nunc a tortor fermentum, non semper enim aliquam. Praesent vulputate nulla at dui dapibus, a placerat lacus auctor. Donec faucibus tortor elit, vitae bibendum mi pharetra eget. Etiam semper pellentesque elit, ac feugiat metus interdum non. Vivamus sed mauris porttitor, tincidunt tortor quis, aliquet mauris. Maecenas volutpat est et neque vehicula semper.

Vestibulum venenatis nulla nec augue cursus, et tempus ante suscipit. Aliquam varius, justo eget consequat blandit, nibh lacus bibendum nisi, eget rutrum nulla mi vitae libero. Duis vel lorem mi. Etiam vel ipsum vitae neque porta vehicula. Sed sed risus sit amet justo egestas aliquet ut euismod neque. Nullam vestibulum malesuada turpis non cursus. Etiam tristique orci in posuere faucibus. Integer consequat egestas nisl id tincidunt.

Sed sagittis at nisl eget volutpat. Aenean ac tincidunt metus. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Quisque ante nulla, commodo vitae massa ut, varius imperdiet est. Cras quis tellus eget odio luctus eleifend nec ac ex. Phasellus facilisis arcu eget sodales sagittis. Phasellus venenatis vulputate libero eu dapibus. Quisque vestibulum nulla augue, sed aliquam augue finibus nec. Duis sit amet erat blandit, aliquam nulla ac, varius justo. In aliquam posuere mauris vitae eleifend. Donec sodales risus sit amet ipsum efficitur aliquam. Praesent pretium mi et pulvinar lacinia.

Donec at est porta, vehicula mauris ut, luctus tortor. Vivamus rutrum consequat ante, eget aliquam neque aliquam nec. In hac habitasse platea dictumst. Vestibulum lacinia lobortis gravida. Nam efficitur porttitor vulputate. Vivamus pretium dolor quis turpis ultricies, venenatis molestie ipsum porttitor. Donec sagittis pulvinar condimentum. Pellentesque consectetur risus ac justo feugiat, sit amet condimentum massa viverra. In vitae ligula ornare, ullamcorper neque a, iaculis tellus. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Sed ligula ante, facilisis eget ipsum id, lacinia ultrices velit. Aliquam eleifend est et volutpat luctus. Pellentesque ac dolor in mi ultricies malesuada. Integer ut arcu sapien. Sed egestas lorem a augue dictum egestas.

Suspendisse vulputate, diam ac pharetra consectetur, metus nulla iaculis erat, vitae pellentesque leo dui sed sem. In non massa at quam congue auctor luctus et erat. Donec interdum, nisi eget cursus lobortis, neque tellus viverra quam, at aliquet sapien velit a sem. Nam id dolor eget quam laoreet porttitor. Proin viverra odio eu dui aliquet viverra. Mauris eget tellus ac leo maximus ornare at sit amet sem. Suspendisse mollis est at neque viverra, eu varius arcu mattis. Integer vitae purus imperdiet lectus gravida ullamcorper ac non mi. Quisque et odio at purus aliquam porta. Interdum et malesuada fames ac ante ipsum primis in faucibus. Etiam posuere est a ipsum malesuada, a elementum diam ullamcorper. Mauris scelerisque, odio at tempor tincidunt, elit libero tincidunt nisl, vel hendrerit ante leo at nunc. Ut at sapien luctus, ultricies ante id, faucibus libero. Quisque viverra ante sit amet enim vestibulum, non aliquet purus sagittis. Integer gravida dolor sit amet erat placerat venenatis. Mauris sit amet nibh quis lectus ultrices facilisis in id nisi.

Sed lacinia tempor justo. Sed congue ante egestas enim faucibus, et accumsan erat varius. Morbi auctor ac dolor quis pulvinar. Pellentesque suscipit scelerisque ex eget pharetra. Morbi hendrerit quam eu mattis iaculis. Donec molestie placerat mauris, placerat efficitur dolor feugiat id. Duis et condimentum sem, nec lobortis tellus. Maecenas et pretium turpis. Vivamus at nisi quis magna aliquam aliquet eu a est. Quisque consectetur mi et posuere dapibus. Sed nec iaculis diam. Etiam ipsum ante, interdum quis tincidunt at, finibus ut odio.

Quisque aliquam at est vel ultricies. Praesent bibendum luctus tellus, a porttitor risus consequat efficitur. Duis rhoncus diam mi, vitae lobortis urna eleifend sed. Nulla imperdiet ac sapien eu ultrices. Nullam quis dictum nisi. Nunc a bibendum est, a efficitur nisi. Praesent condimentum rhoncus felis, non gravida sem fringilla laoreet. Proin tempor dui urna. Suspendisse egestas a nisl sit amet tincidunt. Donec a nisi eleifend, malesuada velit sed, interdum nulla. Nunc condimentum tempor libero, nec pharetra nulla auctor et.

Quisque vel enim lorem. Maecenas sem massa, mattis vitae enim nec, tristique venenatis odio. Vivamus laoreet eros eu bibendum accumsan. Nullam pretium quam non est iaculis, a sollicitudin arcu laoreet. Phasellus sapien dolor, condimentum non urna euismod, vehicula tristique tortor. Maecenas imperdiet ex eget cursus hendrerit. Donec dapibus auctor erat sit amet volutpat. Aenean quis ex efficitur, mollis neque sit amet, hendrerit sem. Phasellus nec ex at massa mattis placerat a eu risus.

Sed facilisis laoreet vehicula. Integer non sollicitudin dui. Vestibulum id egestas eros. Morbi malesuada, leo imperdiet euismod tincidunt, nunc leo semper arcu, egestas varius turpis metus eu nisl. Fusce suscipit metus tellus, ut laoreet velit feugiat sit amet. Integer auctor, lacus in sodales efficitur, dolor arcu luctus risus, id laoreet ex enim quis nulla. Duis bibendum at ante ac pellentesque. Nullam sit amet leo iaculis, posuere diam sit amet, egestas velit. Cras eu maximus sapien. Quisque vitae posuere est. Sed lectus sapien, ullamcorper id elit sed, bibendum tristique dui. Sed sagittis viverra ex, tristique condimentum ligula blandit vel. Quisque rhoncus convallis ante non laoreet. Phasellus arcu ante, fringilla at sollicitudin eget, dignissim nec risus.

Pellentesque accumsan aliquet elit, consectetur finibus tellus gravida et. Maecenas vel lectus sed ipsum laoreet eleifend. Pellentesque ac dignissim justo. Nulla pulvinar vulputate laoreet. Sed purus velit, suscipit vel arcu eget, ultrices convallis magna. Nunc quis nunc quis lacus tempor tempus vel vitae ex. Duis sit amet dui nec eros vestibulum laoreet. Cras in orci eleifend nulla consequat tristique vel at risus. Quisque vestibulum rutrum mauris, a dapibus neque dignissim et. Sed hendrerit imperdiet felis, vel consequat turpis ultrices quis. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Aliquam ultricies egestas dui sed ultrices. Nam enim mi, cursus non viverra a, rutrum sed augue. Duis fringilla quam id varius faucibus.

Maecenas varius pellentesque pretium. Morbi mollis ut odio at posuere. Mauris ac justo lorem. Sed in velit lorem. Proin id lectus mi. In vulputate nisi vitae turpis fringilla porttitor a at sapien. Cras a accumsan mi. Donec non semper urna. Etiam semper diam ac ultrices malesuada. Ut iaculis gravida enim, vitae porttitor arcu convallis sed. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Pellentesque rutrum est lorem. Donec bibendum viverra auctor. Etiam lacinia, magna eu fermentum mollis, nisi diam rutrum lacus, et ultricies sapien ex ut nisi. Nulla viverra, nulla a rhoncus feugiat, erat ligula feugiat orci, ut ornare urna leo nec massa. Proin non metus mollis, convallis risus in, fermentum lectus.

Curabitur mi enim, accumsan placerat diam a, consequat venenatis orci. Ut accumsan a neque et rutrum. Ut orci orci, ultricies sit amet nibh eu, euismod accumsan massa. Integer dictum eu nibh ut consequat. Duis sed venenatis est, pellentesque bibendum tellus. In suscipit enim id gravida vulputate. Mauris ac quam placerat, rutrum lacus elementum, dignissim quam. Integer interdum, sapien bibendum aliquet venenatis, elit ex cursus risus, ac fringilla ex sem eget enim. Aliquam sit amet tellus ac lacus sodales dictum vitae sed velit. Fusce nibh ligula, rhoncus at sodales a, pellentesque id eros. Praesent ultrices ipsum erat, ut dapibus velit convallis non. Nullam suscipit, erat ac facilisis pharetra, elit erat vehicula lorem, at laoreet ligula erat sit amet nisi. Curabitur egestas, turpis in consequat cursus, lacus nulla lobortis lorem, nec pharetra tortor neque vitae nulla. Fusce suscipit eros eget molestie porttitor. Morbi ac arcu enim.

Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Pellentesque fringilla, urna sed cursus mollis, lacus velit commodo est, ac tincidunt dui dui nec libero. Morbi dignissim suscipit turpis non auctor. Cras vel lacus eget tortor accumsan blandit vitae ut justo. Pellentesque maximus nibh a nisl hendrerit tempor. In arcu ex, imperdiet in nulla ac, sollicitudin vehicula sem. In hac habitasse platea dictumst. Nunc viverra lorem justo, nec tempor lorem ornare nec. Donec hendrerit augue dictum dolor accumsan feugiat. Sed quam ligula, consequat ut condimentum vitae, maximus finibus lacus. Fusce in efficitur risus. Morbi interdum sagittis arcu, eget efficitur risus vehicula ac. Phasellus vestibulum ultricies eros id suscipit. Nullam bibendum feugiat turpis, et pulvinar urna aliquam a. Fusce ut ligula venenatis, blandit elit vel, ornare sem.

Fusce non lacus porttitor, ultrices enim porta, ultrices est. Duis mattis quam at metus volutpat, eget ornare tellus vulputate. Donec sed tristique urna, vel bibendum quam. Quisque quis pellentesque nulla, eu tempor est. Curabitur eget tempus nisl, rhoncus tincidunt metus. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. Donec iaculis, lorem faucibus semper maximus, lorem odio finibus sapien, ac facilisis ex turpis sed arcu. Curabitur non pulvinar ex, ultricies maximus sem. Nunc vestibulum arcu ornare urna ornare, at commodo neque scelerisque. Donec sit amet urna at nulla consectetur faucibus vitae in velit. Praesent non lobortis orci, ut convallis nunc. Ut tempus purus mi, eget faucibus neque aliquet fringilla. Aenean aliquet, dolor id ullamcorper gravida, odio tellus tempus nunc, ultrices pretium nisi risus in lorem. Sed in gravida tellus, vitae pellentesque lectus. Nam non leo non ante commodo pharetra a nec tortor. Quisque massa enim, ornare in semper vel, vestibulum at ligula.

Nam commodo libero non ipsum elementum auctor. Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Nam semper facilisis magna, non vulputate est tristique ut. Vestibulum ac ipsum vitae tortor consequat elementum. Mauris tempor augue sit amet gravida volutpat. Sed a maximus lectus. Sed eu dui at neque consectetur dictum vulputate sit amet erat. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Etiam sit amet tempus tortor. In quis eros et nisi condimentum iaculis eu non enim. Nullam neque ex, suscipit ut sodales id, consectetur vehicula nisi. Aenean ultrices nisl malesuada dui tincidunt egestas. Morbi finibus molestie ligula, eu dictum tellus accumsan et.

Integer quis justo a turpis laoreet mollis ut nec orci. Quisque ut lectus vulputate, mollis est quis, porttitor magna. Aliquam erat volutpat. Morbi sed consectetur libero. Morbi volutpat id risus vel sagittis. Duis posuere velit a bibendum malesuada. Nam ut dolor at ex laoreet pretium. Integer sem quam, posuere et ultrices quis, eleifend id orci. Nulla facilisi. Ut ornare scelerisque mi id eleifend. Pellentesque blandit mauris lacus, eget consectetur nisl suscipit et. Sed id orci non nisl lacinia pretium. Quisque hendrerit nisi vitae lorem porttitor dapibus. Vivamus eget sapien id ligula aliquam tristique vitae vitae sem. Donec quis velit non magna iaculis sollicitudin vitae vel augue.

Fusce aliquet nunc sit amet odio venenatis commodo. Nulla pharetra sagittis malesuada. Vestibulum vehicula eleifend justo eu accumsan. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Quisque nec mi commodo, dignissim massa eget, imperdiet felis. Donec pulvinar magna sed lobortis sodales. Nullam elementum auctor lorem, ut pulvinar nunc luctus vitae.

Vestibulum rutrum molestie nunc vel rutrum. Nam ac sem posuere, elementum erat fringilla, pretium diam. Nullam ac neque auctor, malesuada lectus et, placerat libero. Duis a enim sodales, rhoncus nunc mattis, bibendum ex. Nunc quam purus, finibus sagittis nunc bibendum, sagittis fermentum mauris. Aliquam augue est, pretium quis leo in, interdum feugiat nibh. Maecenas elementum quis dolor at semper. Nunc neque nisl, sollicitudin in lacinia sed, venenatis auctor sem. Nam ultricies, ligula vel egestas ullamcorper, quam arcu placerat nisl, pellentesque porta dui augue sed diam. Phasellus in ex eu ante interdum ultricies. Proin id massa finibus, ultrices justo eget, luctus mauris.

Ut sit amet bibendum lacus, et placerat nisi. In auctor eros non elit sollicitudin efficitur. Curabitur a ultricies velit. Nunc aliquet tincidunt dignissim. Mauris et purus eros. Praesent vitae felis vulputate, feugiat libero a, tincidunt elit. Pellentesque nulla quam, commodo id eros nec, egestas mollis sem. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae; Phasellus tempor quam sit amet dui vehicula convallis. Nulla faucibus sem elit, id tempus ipsum egestas at. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae; Nulla facilisi. Nullam ante nulla, mollis posuere tortor ut, hendrerit feugiat lorem.

Proin luctus nunc accumsan, venenatis nibh nec, rutrum sapien. Morbi faucibus nulla id posuere pellentesque. Praesent fringilla ultricies maximus. Mauris tempor malesuada eros ac consequat. Donec commodo commodo felis ac laoreet. Vestibulum pretium facilisis gravida. Proin odio orci, viverra ut elit eu, auctor elementum turpis. In at fermentum elit, ut ornare magna. Sed ultricies viverra ultrices. Mauris aliquet odio at dui ultrices imperdiet.

Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Sed sit amet semper tellus. Proin vulputate nisi id aliquet imperdiet. Quisque varius dui sed suscipit feugiat. Donec placerat ultrices erat ut mollis. Quisque ultrices dolor dolor, in vestibulum tellus laoreet fermentum. Maecenas faucibus, tellus ac blandit venenatis, velit tortor luctus nulla, consectetur tempor ipsum ex eu eros. Praesent sed odio malesuada sapien aliquet dignissim at quis nunc. Phasellus scelerisque pulvinar dolor vitae egestas. Ut consequat elit sem, vulputate hendrerit massa condimentum et. Interdum et malesuada fames ac ante ipsum primis in faucibus.

Quisque sit amet nibh a magna lobortis tempus vitae a metus. Maecenas faucibus urna nec dui accumsan mattis. Nulla pulvinar massa vitae dictum consectetur. In ac luctus tellus, quis gravida dui. Donec volutpat nunc ipsum, eu scelerisque dolor pulvinar quis. Nam at nisl et magna imperdiet lacinia. Mauris convallis mollis lectus, vel sagittis tortor congue sed. Nullam id urna tempus, semper dui at, gravida lorem. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed dapibus lobortis vestibulum. Pellentesque diam mi, hendrerit et diam ac, condimentum porta sem. Nulla nulla dui, pulvinar sit amet libero in, blandit interdum metus. Maecenas mattis tempus nulla, quis pulvinar eros.

Praesent vestibulum, dui commodo viverra gravida, metus mauris blandit augue, ac interdum libero nunc sit amet tellus. Morbi eget euismod diam. Nulla non malesuada est. Nam leo purus, congue eu ante eget, finibus vulputate turpis. Aenean finibus lorem quis accumsan efficitur. Nulla nec tincidunt sapien, nec blandit tortor. Duis rhoncus fringilla urna, et laoreet lacus feugiat ut. Maecenas lobortis cursus nisl ac tincidunt. Nunc tincidunt mattis augue sit amet venenatis. Donec nec nisi gravida, suscipit lorem vitae, commodo sapien. Quisque orci magna, porta nec eros ut, tempor commodo lectus.

Vestibulum lacinia nibh sit amet lectus fermentum hendrerit. Integer facilisis neque vestibulum porttitor fringilla. Mauris sit amet tincidunt arcu, convallis condimentum massa. Pellentesque sollicitudin molestie tristique. Donec augue dui, mattis sed tortor ut, feugiat lobortis ligula. Mauris porta mauris at neque tincidunt cursus. Phasellus at tempor orci. Pellentesque tincidunt eu tortor et dapibus. Integer sit amet sagittis ligula, vitae finibus magna. Fusce ac fermentum nibh. Duis ut ex massa. Proin lorem orci, venenatis ac molestie et, egestas vel ligula.

Aenean et laoreet lorem. Maecenas tempor ultricies congue. Aenean dapibus posuere lacus sit amet faucibus. Integer id sem ac libero dictum consectetur. Aenean turpis urna, sodales vel faucibus sed, aliquet a velit. Sed vel nulla ut justo volutpat ornare. Suspendisse at dignissim turpis, ac pharetra est. Vivamus ultrices justo sem, vitae tempor libero sagittis sed. Donec maximus porta augue nec viverra. Integer tellus urna, gravida vel lectus vitae, tincidunt facilisis odio.

Etiam in velit nisi. In hac habitasse platea dictumst. Aenean lobortis venenatis diam, vel fringilla turpis vehicula tincidunt. Proin id semper sapien, nec convallis augue. In auctor commodo sollicitudin. Proin rutrum euismod risus nec ultricies. Praesent et interdum nibh. Integer condimentum mi vitae efficitur tincidunt. Vestibulum blandit nulla velit, non pharetra nunc dapibus quis. Donec ultricies risus nec vestibulum accumsan. Mauris nec ipsum lobortis, dignissim mi et, volutpat augue.

Mauris laoreet, erat sed porttitor placerat, erat enim aliquet urna, sed sagittis mauris dui nec lacus. Phasellus magna nisl, vulputate sed neque pulvinar, ornare dapibus ante. Sed eu interdum ex. Nam eu odio et mi accumsan pulvinar eget at dolor. Praesent sodales sem neque, vitae hendrerit metus tristique nec. Ut felis lorem, euismod ac magna eu, aliquam varius nibh. Nullam at ipsum ut turpis facilisis mollis quis nec mi. Nunc vel molestie velit. Nunc at volutpat enim, at consequat magna. Nulla turpis massa, pharetra ac purus ac, elementum iaculis dolor. Etiam ornare venenatis nibh a fermentum. Duis ornare sapien non erat euismod scelerisque.

Nam vulputate nibh arcu, non pellentesque nulla pulvinar maximus. Donec vulputate augue nisi, a venenatis nunc tristique in. Suspendisse potenti. Maecenas tristique venenatis nisi, id malesuada elit auctor vulputate. Aliquam bibendum pulvinar lorem, quis mollis sapien interdum ut. Mauris consectetur id turpis varius malesuada. Morbi id velit at tortor hendrerit finibus. Vivamus at augue odio. Phasellus et metus a leo convallis mollis. Quisque in mauris at mauris aliquet interdum.

Curabitur suscipit sagittis feugiat. Suspendisse id molestie sapien. Mauris viverra felis dui, ut egestas metus ultrices non. Suspendisse viverra orci nec tellus euismod porttitor. Aenean suscipit mauris augue, eu efficitur leo finibus in. Pellentesque at egestas ante. Phasellus sed imperdiet erat. Vestibulum placerat bibendum turpis sit amet tempor. Donec a lectus sodales, tempus velit vitae, feugiat sem. Fusce ullamcorper sem in arcu molestie pellentesque. Quisque at ante tempus, auctor ante et, porta ante.

Integer in nunc consectetur, consequat mauris in, iaculis felis. Ut vehicula id felis at fermentum. Donec vitae suscipit est, in aliquet quam. Aenean rutrum lectus ac mauris malesuada, in tincidunt ante tempor. Morbi a ultricies est. Integer leo nibh, congue eu elit nec, imperdiet egestas elit. Nunc vitae dapibus elit. Integer ut accumsan enim. Sed tristique vitae odio ut placerat. Aliquam ullamcorper iaculis lectus, vitae ultrices mi auctor vel. Fusce est dolor, condimentum et bibendum ut, molestie ut quam.

Aenean sollicitudin euismod metus, quis molestie sem. Morbi id commodo libero. Aliquam tincidunt justo sit amet mauris convallis ornare. Quisque pretium auctor odio, vitae porttitor neque porttitor id. Cras cursus condimentum sem, non pulvinar purus laoreet sit amet. Aliquam in ultricies massa, ut tincidunt ante. Suspendisse ac urna erat.

Quisque ornare enim eu maximus bibendum. Aenean sem dolor, blandit a metus id, lobortis fermentum tellus. Maecenas viverra dui pellentesque arcu ullamcorper varius. Suspendisse potenti. Proin vestibulum feugiat massa, eu interdum erat sollicitudin id. Ut id dignissim leo. Donec viverra, risus sodales facilisis scelerisque, nibh mauris sagittis enim, ac iaculis urna leo at erat. Aenean porta hendrerit nibh a tincidunt. Nam consequat scelerisque ornare. Etiam non justo vulputate dui laoreet iaculis nec vel dolor.

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nam hendrerit nisl turpis, vitae molestie orci tempus ut. Ut varius augue lobortis, euismod diam ac, tempor urna. Curabitur sem ex, semper non elementum vitae, hendrerit nec ligula. Etiam fermentum ex nisi, suscipit facilisis nulla viverra eget. Ut quis volutpat diam. Curabitur ac viverra est, non maximus nisl. Vivamus vel pharetra nibh. Morbi rhoncus efficitur ante non facilisis. Duis ac neque dictum, tincidunt risus nec, congue nulla. Ut accumsan turpis rhoncus auctor condimentum. In nibh risus, fringilla eu tristique a, tempus vitae ante. Sed sit amet purus quis velit condimentum faucibus. Ut orci quam, dapibus ut ornare non, consequat non enim. Nunc orci risus, gravida a tellus et, sagittis auctor magna. Quisque cursus turpis et dignissim aliquam.

Quisque placerat nisi nec ipsum placerat, in pretium risus placerat. Mauris dui mauris, maximus quis ultrices sed, viverra non purus. Mauris sed justo tellus. Proin at malesuada neque. Sed id iaculis elit. Vivamus vestibulum id felis et commodo. Nulla dui enim, luctus ut risus quis, malesuada ullamcorper mi. Sed rhoncus purus at sollicitudin viverra. Nam sem dui, porta vitae ex eu, volutpat pretium ex. Nunc cursus elit mollis nibh porttitor, non cursus dolor maximus. Cras elementum malesuada lacus et volutpat. Donec sed neque at dolor interdum tincidunt.

Praesent pellentesque fermentum condimentum. Vivamus at mauris blandit, convallis ex tincidunt, eleifend mi. Donec at placerat metus. Nam lorem arcu, imperdiet quis lacinia sed, commodo nec risus. Aenean sed arcu a sapien maximus accumsan. Nam elementum maximus congue. Donec dictum nisi sed condimentum gravida. Cras imperdiet magna scelerisque diam finibus aliquet. Donec malesuada metus id dolor euismod, ut faucibus magna imperdiet. Nulla facilisi. Suspendisse tempor, urna nec tristique venenatis, nisl nulla pellentesque justo, id efficitur magna mauris a nisi. Curabitur ultricies sodales erat. Nullam luctus pretium ipsum. Praesent et metus et lacus pretium tincidunt. Cras fringilla, erat aliquam gravida viverra, ante risus condimentum turpis, ut egestas tortor lectus vel libero.

Pellentesque at quam vehicula, elementum urna quis, rhoncus dui. Sed nec lectus ex. Sed sem quam, fringilla ac porta a, sollicitudin vel ex. Nulla porttitor libero at nibh feugiat tincidunt. Praesent eu elit a ligula aliquet efficitur in id elit. Sed ut tincidunt dui. Duis ullamcorper, elit mollis consequat malesuada, libero justo pulvinar neque, quis mollis justo massa sed lectus. Cras quis lacus sapien. Fusce pretium libero at tempor egestas. Vivamus diam lorem, laoreet a orci in, luctus elementum magna. Sed maximus ligula ultrices massa tempor, vel vehicula nunc porttitor. Donec tortor justo, iaculis non enim eget, cursus feugiat ante. Nulla hendrerit at eros sit amet mattis.

Orci varius natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Aenean vel neque in dolor rutrum laoreet. Ut nec tempus tellus. Donec pulvinar tellus ut libero molestie, sit amet aliquet neque lacinia. Integer mattis turpis at ultricies rutrum. Duis auctor tellus non erat imperdiet, vitae tristique tortor posuere. Aenean mi lorem, placerat id aliquam nec, dictum id massa. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Mauris sed nulla ut erat cursus pharetra. In rhoncus mi sed lorem pellentesque pellentesque. Etiam blandit, ipsum in ullamcorper congue, sem tortor efficitur justo, a posuere sapien leo in purus. Quisque justo arcu, iaculis ut lorem ut, tempor dignissim velit. Praesent elit velit, malesuada ac sem id, ultrices vulputate risus. Nulla suscipit vulputate orci sit amet finibus. Nam et metus neque.

Duis molestie neque et hendrerit venenatis. Vivamus efficitur aliquam efficitur. Vivamus dui orci, consequat venenatis mollis in, lacinia a tellus. Nulla in risus ac libero molestie porta ut sit amet lorem. Donec blandit bibendum eleifend. Pellentesque scelerisque odio at venenatis commodo. Etiam eu massa tellus. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae; Sed mattis tristique sapien eget lacinia. Pellentesque ornare ornare est, vel viverra quam venenatis vitae.

Nam lectus ipsum, consequat a ipsum sed, dictum consectetur lectus. Proin elementum neque sit amet arcu semper fermentum. Phasellus at rutrum ligula. Aenean pharetra feugiat interdum. Etiam malesuada, odio eget dignissim hendrerit, eros arcu consequat diam, non rutrum diam augue a metus. Donec ut egestas felis. Aliquam tellus odio, elementum vel sodales vitae, sodales at leo. Donec pharetra justo scelerisque ultricies dictum.

Curabitur sodales ac lacus in ullamcorper. Donec et auctor ex, eu consequat elit. Praesent finibus nec sem a consectetur. Aliquam erat volutpat. Proin dapibus justo tortor, vitae porta lorem rhoncus quis. Fusce egestas semper elit, eu elementum diam congue id. Curabitur condimentum sagittis diam at bibendum.

Donec vitae posuere elit. Aenean lobortis, urna quis convallis volutpat, augue erat vestibulum purus, vitae varius nunc sem a velit. In venenatis ornare orci. Nunc nunc lacus, posuere sit amet convallis eu, cursus vitae ante. Praesent semper leo in sem tempor posuere. Mauris a nisi aliquam, consequat nisl et, hendrerit diam. Ut accumsan, erat quis sollicitudin pellentesque, nulla urna condimentum erat, vitae tincidunt justo tellus non velit. Morbi in nisl quis justo pretium ullamcorper et sit amet quam. Quisque ultricies libero eu magna suscipit, sed pellentesque arcu aliquam. Vivamus risus quam, feugiat a porta sed, varius pretium dolor. Suspendisse quis nisi eleifend, cursus dolor at, condimentum purus. Maecenas magna nunc, ultricies ut risus id, venenatis congue enim. Donec vulputate odio ut ante laoreet efficitur. Curabitur augue magna, placerat iaculis libero vel, viverra dapibus mi. Vestibulum dolor urna, laoreet at nulla vitae, mollis congue lacus. Nullam laoreet sem vitae mi finibus condimentum.

Phasellus ut ante eu urna fermentum suscipit. Vivamus convallis pellentesque tincidunt. Ut vitae aliquet massa. Suspendisse volutpat mi in tortor dictum, sed volutpat ipsum efficitur. In fermentum venenatis placerat. Vivamus eget finibus risus. Pellentesque ipsum purus, finibus et dui eget, dapibus mattis libero. Proin eu lacinia nibh.

Aenean varius sodales dolor, in luctus ante laoreet at. Cras sapien quam, suscipit non eleifend et, bibendum eu magna. Donec quis gravida sapien. Morbi nisi felis, facilisis ut mollis ac, iaculis sed velit. Pellentesque vel lectus ligula. Ut et accumsan nunc. Vivamus fermentum mattis arcu. Mauris nec semper sapien. Nullam lacinia id massa ut luctus. Morbi lobortis mi nec leo sollicitudin, ac ultrices elit rutrum. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae; Vivamus tristique, lacus in vestibulum mollis, est leo imperdiet lectus, lobortis mollis quam leo in mi. Vivamus aliquet risus massa, eget laoreet leo elementum eget.

Cras urna ex, aliquam a elit sit amet, sodales efficitur enim. Nunc vel sodales purus, sit amet aliquam quam. Sed vitae pellentesque tellus, et fringilla neque. Aliquam bibendum euismod ornare. Aenean sed posuere nisl. Aliquam consectetur ligula enim, id pharetra risus bibendum quis. Fusce tempus sed ipsum in tempor. Sed erat ante, interdum tincidunt ornare ac, commodo eget sem. Curabitur eget massa elementum justo molestie efficitur. Proin tempor et dui vel molestie.

Curabitur vulputate aliquam tortor eget eleifend. Vivamus auctor suscipit orci, vel congue quam iaculis id. Suspendisse elementum neque in maximus blandit. Suspendisse lectus augue, porta ac mauris nec, mattis bibendum tellus. Suspendisse consequat quam ac interdum porttitor. Suspendisse feugiat libero ex, at luctus risus vehicula vel. Phasellus tempus imperdiet enim, bibendum congue arcu. Ut volutpat elit eget sodales suscipit. Nulla vulputate, ante sed maximus rutrum, velit sem euismod nulla, in malesuada velit orci sit amet risus. Duis vitae molestie nibh, vitae euismod neque. Ut massa velit, sodales facilisis orci eget, congue pharetra nunc.

Quisque arcu nibh, convallis at eros vel, faucibus cursus justo. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Phasellus scelerisque libero lectus, in egestas magna rhoncus nec. Suspendisse sagittis volutpat leo, ultricies auctor nisl ultricies sit amet. Nullam blandit, metus at feugiat viverra, orci ex suscipit diam, nec gravida est sapien non diam. Duis non massa sapien. Fusce pretium tempus vestibulum.

Integer convallis feugiat diam ut cursus. Pellentesque eleifend lacus dolor, id vehicula tortor consequat eu. Nunc id accumsan nulla. Suspendisse nisl lorem, tempor id posuere fermentum, molestie vel velit. Nunc porta magna ac felis interdum, a fringilla turpis posuere. Proin lacus dolor, volutpat eget mattis in, sollicitudin nec ligula. Maecenas quis nibh accumsan, posuere mauris vulputate, blandit urna. Aliquam tristique cursus molestie. Fusce lacinia lacus ac tempus dignissim. Vestibulum ac laoreet mauris, a fermentum dui. Nunc ut nisl non justo egestas finibus eu ut diam. Donec hendrerit consectetur mi quis pellentesque. Integer vehicula interdum erat sit amet egestas. Sed porttitor massa quis magna congue tempor. Duis vulputate euismod nulla vitae tempus. Vivamus porta vel felis sed porttitor.

Nam nec vehicula diam, quis tincidunt turpis. Integer sit amet elit velit. Aliquam elementum nisi gravida, condimentum leo nec, sodales lorem. Mauris volutpat, risus vitae iaculis finibus, felis quam aliquet turpis, non ultricies nunc felis sed mi. Duis mattis ante sed laoreet blandit. Sed consectetur augue in nibh accumsan porttitor. Praesent vulputate vestibulum efficitur. Nam et risus ipsum. Donec pellentesque enim semper malesuada elementum.

Suspendisse at mauris dui. Morbi cursus est lectus. Nam viverra, dolor finibus volutpat ornare, urna dui fringilla diam, vel efficitur tellus lacus tristique magna. Curabitur sodales nec quam ac iaculis. Cras sagittis, dolor ac feugiat venenatis, arcu odio sollicitudin enim, sit amet eleifend enim nulla a mauris. Donec id elementum mi. Mauris ullamcorper ipsum faucibus, auctor nisl at, euismod odio. Suspendisse vel sollicitudin leo. Phasellus vitae ex tristique, tempus libero vitae, tempus nibh. Fusce imperdiet lorem ac orci vestibulum, vehicula malesuada lorem eleifend. Phasellus feugiat dolor est, at vulputate arcu viverra quis. Vestibulum vestibulum malesuada lectus at euismod. Proin interdum, orci eu dictum aliquam, odio tortor elementum nisl, eu elementum lorem diam eget lorem.

Nunc orci purus, feugiat sed tellus ut, ultricies varius ex. Pellentesque bibendum ante eu arcu lobortis vulputate. Duis pretium eget dolor nec pretium. Sed ac vestibulum nisi, et dignissim nisl. Vestibulum ut orci erat. Sed neque libero, iaculis sed maximus id, sagittis vitae risus. Quisque non sagittis dui. Donec tempor a metus tincidunt rutrum. Duis rutrum vitae tellus sed luctus. Vivamus eu consectetur neque. In hac habitasse platea dictumst. Phasellus ultricies, sem nec hendrerit egestas, purus leo volutpat quam, eget commodo elit elit feugiat nibh. In maximus est nec dolor eleifend aliquam. Donec sed tristique tellus. Aenean molestie lorem ac faucibus fermentum. Nulla dapibus metus in dolor accumsan, a sodales lacus vestibulum.

Nam in dapibus tellus, ullamcorper congue nibh. Praesent id imperdiet augue, vel semper nisi. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos. In bibendum eros et leo condimentum faucibus. Nullam lorem ipsum, pretium ut eros placerat, volutpat malesuada tortor. Nunc ullamcorper blandit rhoncus. Fusce vitae ante nec felis sodales aliquet quis vel magna. Sed maximus libero consequat justo cursus vestibulum. In sollicitudin gravida ullamcorper. Aliquam finibus mi vel magna bibendum, efficitur congue quam pharetra. Sed aliquet, sapien sed iaculis fringilla, sapien dolor viverra eros, tincidunt varius felis quam et metus. Fusce ac risus tellus. Phasellus sit amet sagittis mauris. Vivamus at dictum libero. Ut auctor elit sapien, eu condimentum nunc efficitur sit amet. Phasellus sodales lorem sit amet nibh posuere, id varius nisi bibendum.

Vivamus consectetur metus quis nisl porttitor, a euismod ligula scelerisque. Sed ut elit pretium velit eleifend accumsan in vel mauris. Etiam ultricies pharetra purus. In quis molestie ante. Pellentesque gravida porta lacus non laoreet. Etiam interdum mattis odio quis porttitor. Sed lobortis efficitur fermentum.

In euismod mauris quis ipsum consequat, sed laoreet lorem efficitur. Duis finibus nibh lorem, eu luctus enim ultricies quis. Aenean condimentum pellentesque commodo. Fusce nec lectus eleifend, semper velit quis, venenatis libero. Maecenas sed ligula ac leo maximus ultrices vel a lorem. Fusce et mi id leo luctus egestas at sed augue. Nullam at blandit libero. Vivamus et aliquet tortor. Suspendisse potenti. Fusce ac neque at mauris mattis euismod. Praesent ut eros nibh. Donec gravida vitae urna ut pellentesque. Mauris dapibus blandit felis, id lacinia justo maximus quis. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos.

Cras cursus scelerisque orci et tristique. Suspendisse sit amet vestibulum dui, vitae viverra lacus. Nunc porttitor eros ut leo bibendum commodo. Donec lobortis sem consequat velit venenatis, sed consequat risus sodales. Proin lobortis magna nec nibh sodales mollis. Vivamus ac imperdiet nibh, a consectetur felis. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Morbi sed nulla vehicula nibh ornare maximus et quis enim. Nunc at auctor velit. Integer at risus blandit, viverra turpis sit amet, tempor magna. Vestibulum aliquam mattis velit id eleifend. Sed sed felis nec velit placerat tempus. Etiam dolor arcu, consectetur et fermentum nec, dictum et libero. Fusce eu viverra odio. Mauris velit tellus, lobortis eget est ac, scelerisque sollicitudin massa.

Suspendisse potenti. Etiam eu orci ante. In efficitur eu nulla et volutpat. Maecenas id lacinia nunc. Phasellus libero ex, sodales eget fringilla sit amet, blandit ac velit. Nullam efficitur ullamcorper turpis non convallis. In hac habitasse platea dictumst. Vivamus non arcu rhoncus, finibus arcu sed, lacinia urna. Duis commodo convallis eros, eget pharetra leo blandit vel.

Maecenas facilisis blandit vulputate. Etiam libero quam, tempor nec mauris finibus, venenatis finibus nulla. Fusce maximus ullamcorper nulla sit amet tempor. Ut lorem metus, placerat nec dui sit amet, malesuada placerat augue. Vestibulum porttitor dui et augue viverra pharetra. Donec commodo tortor eget mattis finibus. Interdum et malesuada fames ac ante ipsum primis in faucibus. Curabitur accumsan mi in ligula mollis, a finibus nibh tristique. Vivamus aliquam nisl at augue aliquam, et ultricies ipsum luctus. Nam consequat purus nec tempus interdum. Nam viverra dictum mauris tristique porttitor. Quisque dictum turpis eleifend fermentum pharetra.

Aenean a justo consectetur, aliquet purus vitae, lobortis dolor. Suspendisse nibh ipsum, ornare ac purus eleifend, fringilla finibus ligula. Nam vel turpis et eros lacinia ornare. Nam tristique eget tellus et dictum. Curabitur ac nunc sed tortor semper pharetra id id turpis. Donec ultricies risus bibendum luctus vehicula. Praesent ac tellus bibendum, feugiat tellus vestibulum, vehicula neque. Suspendisse aliquet orci nisi, id accumsan lectus pellentesque sed. Mauris facilisis odio nulla, quis venenatis nibh mattis eu. Vivamus eget scelerisque est. Vestibulum efficitur sem eu risus viverra, non varius ipsum convallis. Morbi nec semper nunc. Nulla malesuada quam sit amet nibh sollicitudin fermentum. Integer suscipit et elit quis vulputate.

Pellentesque accumsan sapien dui, at consectetur enim semper in. Donec quis feugiat enim, vitae pellentesque tortor. Proin dapibus dolor a arcu luctus accumsan. Pellentesque dignissim lectus id maximus dignissim. Duis quis pellentesque lorem, vel ornare mi. Nunc ac tempor dui. In consequat ac metus et imperdiet. Suspendisse potenti. Integer dictum, diam nec rhoncus faucibus, risus dolor vulputate nulla, nec viverra mi arcu a elit.

Suspendisse eget erat ac sapien pretium maximus ut non metus. Donec ac posuere turpis. Pellentesque suscipit bibendum sapien quis ultricies. Curabitur varius lectus id consectetur sollicitudin. In rutrum elementum leo, sed finibus diam viverra ac. Maecenas eget orci non justo faucibus rhoncus. Vestibulum tincidunt dolor eu orci sodales scelerisque.

Suspendisse vitae maximus enim. Quisque rhoncus eros id augue lacinia, a dignissim mi auctor. Integer scelerisque lacinia odio, scelerisque mattis ligula dignissim a. Vivamus gravida vel tortor nec porttitor. Etiam eu dui in sapien euismod vestibulum. Fusce vehicula, ipsum a vulputate ornare, augue mi varius leo, eu imperdiet lectus dolor ut nisl. Sed nec ipsum id turpis fringilla accumsan imperdiet sed ante. Donec laoreet diam risus, ut sollicitudin augue laoreet vitae.

Donec sodales ut augue pharetra consequat. Duis sit amet vestibulum elit. Aliquam eu magna sed magna vulputate vulputate at et lorem. Morbi venenatis nunc in orci dapibus mollis. Nunc imperdiet pretium nisi at commodo. Sed vel maximus sem. Donec pulvinar, purus ac luctus dictum, erat elit vulputate justo, molestie efficitur nunc enim et diam. Aliquam aliquam, justo eu mattis mollis, ipsum lacus commodo ipsum, at rutrum augue justo eu purus. Duis sit amet est eget dolor egestas tempus eget id felis. Etiam eget purus vel lectus maximus porttitor scelerisque ac erat. Curabitur tincidunt lacus eget mollis hendrerit.

Integer efficitur, dolor vehicula suscipit feugiat, turpis nisl rutrum ex, sit amet volutpat nunc elit ac nibh. Nulla sem quam, pellentesque molestie ante vel, vulputate rhoncus mauris. Cras feugiat cursus velit id volutpat. Nullam sagittis quis diam eu commodo. Fusce ut nisi eget turpis imperdiet ultricies. Suspendisse nec ornare neque. Nunc aliquam orci quis nunc euismod, ac tempus odio commodo. Donec blandit lorem ac enim scelerisque, et dapibus nisl efficitur.

In vitae tortor pellentesque, posuere ante et, eleifend sem. Pellentesque fringilla mollis augue a tincidunt. Integer a egestas risus. Maecenas semper, elit nec bibendum venenatis, lectus ante tempus sem, eu consequat diam nibh vel magna. Aliquam purus risus, fermentum eget fringilla nec, maximus nec nunc. Quisque commodo elit sit amet dapibus malesuada. Etiam semper auctor suscipit. Nulla convallis ipsum arcu. Sed quis ante egestas, vulputate nulla non, pulvinar libero. Aliquam nulla mi, efficitur a dictum in, finibus a lectus. Vivamus eu urna magna. Donec pharetra porttitor elit nec vulputate. Nulla mattis placerat lacus, ac tincidunt sapien facilisis id.

Vestibulum purus sem, gravida eu sollicitudin sit amet, viverra vitae elit. Aliquam risus neque, vestibulum eget tincidunt eu, laoreet sit amet leo. Aenean et dui vel neque pharetra molestie. Cras sagittis justo id volutpat commodo. Quisque commodo posuere condimentum. Curabitur quis aliquet orci, ac varius turpis. Aenean ut urna finibus, pharetra diam at, ullamcorper purus. Fusce facilisis erat quis elit sagittis hendrerit. Morbi varius magna eget pretium mollis. Phasellus convallis risus ac eros mollis, id commodo purus hendrerit. Etiam in ligula magna. Duis vitae fermentum urna, sed vestibulum elit. Fusce porttitor justo vel ligula accumsan aliquet vel a ligula. Nulla facilisi. Aliquam et sapien libero. Pellentesque pharetra sapien quis dui imperdiet interdum.

Nulla non egestas ipsum. Morbi feugiat feugiat ligula a semper. Nullam nec eros non orci aliquet pretium a quis dui. Ut iaculis, enim et posuere pellentesque, nisi urna euismod massa, vitae tincidunt arcu libero eget elit. Donec tristique, eros ac posuere hendrerit, lorem elit molestie eros, eu fermentum orci sem eget elit. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Pellentesque at libero vitae mauris placerat ultrices sit amet quis est. Duis a gravida magna, ut pharetra urna.

Quisque aliquet sapien eros, non ullamcorper nisi varius in. Ut cursus vestibulum elit at feugiat. In et luctus sem. Nulla et nibh pretium, faucibus nibh non, tempor velit. Ut maximus dapibus nisl, maximus pulvinar ex sollicitudin in. Integer sit amet ultrices odio. Donec id consectetur libero, et luctus massa. Maecenas et sollicitudin lacus. Maecenas ac sem blandit, malesuada quam sit amet, imperdiet nunc.

Nam dapibus est ut magna rutrum, ut bibendum dolor ultrices. Ut risus velit, semper ultricies nisl at, vestibulum efficitur justo. Quisque vestibulum nisi id lectus faucibus, ut iaculis dolor elementum. Morbi vestibulum tellus vitae urna aliquet vehicula. Quisque ultricies metus et augue tristique maximus. Mauris non turpis vel ex malesuada posuere egestas sit amet dolor. Quisque sit amet feugiat justo. Maecenas et venenatis nisl. Cras et metus venenatis, varius leo facilisis, rhoncus lorem.

Suspendisse justo lacus, viverra non dictum eu, laoreet at arcu. Mauris et sodales dui. Nam malesuada libero vitae vestibulum vehicula. Aenean quis sapien ut lorem pharetra aliquet. Nullam at faucibus odio. Donec congue sit amet lectus a ultrices. Aenean aliquam risus turpis, quis accumsan nunc dignissim vel. Ut quis sapien sed orci condimentum porta vitae vitae neque. Nullam elementum congue elementum. Etiam est enim, euismod pharetra risus id, dapibus aliquam mi. Morbi non neque augue. Aenean nec eros id tellus efficitur sagittis. Duis vestibulum, elit non lacinia ultrices, dolor dolor tempor erat, ac tempus neque lacus vel tortor. Curabitur quis ante varius, maximus turpis id, condimentum diam. Morbi luctus lorem a felis ultricies, id semper sapien laoreet.

Integer maximus leo at metus sagittis, ultrices feugiat mauris posuere. In rhoncus porttitor velit eget eleifend. Mauris urna nisi, pharetra ut nisi at, aliquet lacinia leo. Mauris molestie maximus augue, nec blandit magna sagittis et. In tincidunt rutrum metus eget sollicitudin. Phasellus laoreet arcu hendrerit, dictum diam viverra, mattis lectus. Fusce consectetur vulputate nunc sed rhoncus. Pellentesque fermentum nulla nec finibus condimentum. Maecenas sem arcu, volutpat hendrerit ipsum sit amet, convallis interdum metus. Integer facilisis dictum sem, varius ullamcorper mauris sodales ut. Vivamus fringilla mi eros, eget venenatis ligula sagittis non. Cras scelerisque nulla ante, quis porta quam pellentesque a. Nam orci lorem, consectetur sit amet aliquam sed, posuere in nunc.

Vivamus aliquam convallis risus, eu ullamcorper turpis fermentum at. Duis nec augue scelerisque, accumsan erat in, efficitur justo. Mauris et feugiat nulla. In massa dolor, hendrerit at rhoncus et, lobortis id metus. Nunc leo sem, maximus in elit eget, maximus accumsan velit. Quisque commodo condimentum risus, eu tincidunt libero. Nunc eu tellus nulla. Pellentesque dignissim nisl sit amet velit posuere molestie. Ut eget suscipit dolor. Proin eget enim porta, dignissim diam vel, molestie massa. Pellentesque commodo tempus nisl nec laoreet. In luctus, felis id dapibus molestie, elit dolor egestas felis, non fringilla leo tortor ut dui. Quisque gravida, arcu vel imperdiet egestas, quam tortor porta justo, vitae hendrerit quam ante vel lacus. Etiam pretium enim nisl, sed feugiat felis sagittis at. Integer auctor felis eget tortor hendrerit dignissim. Suspendisse ultricies sapien venenatis erat mattis, in laoreet neque finibus.

Phasellus venenatis, magna eget pellentesque pellentesque, urna lacus fermentum dolor, et mollis sapien lacus ac dui. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed in mi sodales augue interdum dictum. Vestibulum viverra ante ut ullamcorper volutpat. Cras tincidunt sit amet sapien nec dictum. Sed neque turpis, volutpat vel erat a, vulputate accumsan odio. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Fusce nibh mauris, dictum id tristique ac, aliquam at sapien. Etiam vel mattis sem, in pretium eros. Vestibulum ante ipsum primis in faucibus orci luctus et ultrices posuere cubilia curae; Fusce ornare faucibus leo id facilisis. Donec at eleifend ante. Suspendisse lacinia nulla in sem congue ullamcorper.

Vestibulum ornare nulla quis faucibus rutrum. Mauris in urna ante. Etiam lorem sapien, sollicitudin vel rutrum sed, suscipit eget dui. Fusce fringilla risus sed tortor porttitor dictum. Etiam ultricies mi vitae turpis dapibus, nec elementum velit faucibus. Sed suscipit tristique magna, vel fringilla elit malesuada non. Sed bibendum hendrerit quam ut rutrum. Sed aliquet, diam vel bibendum ornare, dui urna placerat velit, in suscipit lorem lorem quis sapien. Nullam dictum tellus non est aliquam imperdiet. Fusce ut tempor est. Aenean egestas turpis a ipsum vulputate luctus. Vestibulum molestie augue id mi ultricies fermentum. Sed placerat, mauris quis lacinia blandit, nulla leo ullamcorper felis, ut vestibulum mi risus id augue. Sed ex enim, rutrum in consectetur at, egestas sit amet ipsum. Aliquam tincidunt velit sed iaculis dapibus. Morbi sodales tortor nulla.

Nam id nisi mauris. Nulla facilisi. Duis metus ante, malesuada in imperdiet vel, elementum vitae turpis. Nunc ullamcorper efficitur augue, ut finibus est sollicitudin eu. Pellentesque pulvinar massa a neque commodo, vel finibus nisl cursus. Quisque sit amet cursus turpis. Vestibulum suscipit, dolor eget interdum viverra, libero lectus dignissim leo, sit amet viverra neque risus ac nisi. Integer consectetur mauris sed leo lobortis, nec porta justo euismod. Phasellus id eros augue.

Donec imperdiet massa ac arcu fermentum, ut pellentesque nunc suscipit. Sed pretium porta tincidunt. Vivamus eleifend accumsan elit. Proin porttitor, metus at imperdiet vulputate, tellus mi vestibulum justo, eu tristique nulla ligula ac purus. Quisque facilisis, est sit amet faucibus suscipit, augue ex elementum lectus, nec fringilla nisi nisl quis orci. Nulla vel leo sit amet sem iaculis tempus sed vel est. Aliquam elementum dui id justo bibendum, vitae dictum libero lobortis. Suspendisse potenti. Aliquam tincidunt vulputate placerat. Ut quis vehicula odio, at elementum lacus. Fusce imperdiet felis ipsum, aliquet aliquam magna blandit vel. Donec mattis neque lacus, at gravida nisl ultricies sit amet. Morbi vel orci laoreet, commodo nisi vitae, finibus massa. Suspendisse sollicitudin lorem non felis dictum varius.

Aenean neque mi, varius ac laoreet nec, tincidunt at nulla. Fusce quis dolor sit amet dui imperdiet porttitor nec non justo. Nulla nec leo in ipsum venenatis aliquam. Integer vel cursus velit. Vestibulum tellus ligula, facilisis vel pharetra quis, vehicula vitae turpis. Fusce auctor, tellus eu interdum suscipit, augue velit gravida tortor, sed vulputate libero lorem id lectus. Vivamus id tincidunt quam. Nam vitae enim et nisl tincidunt lacinia. Donec eget enim at nibh gravida sodales. Nam in sapien commodo, suscipit ante ac, imperdiet urna. Nunc id ipsum dui. Integer consequat eros vel ex hendrerit lacinia.

Quisque volutpat malesuada quam a pharetra. Mauris massa nulla, congue eu massa a, sagittis aliquet eros. Fusce interdum, nunc et suscipit bibendum, dolor nulla gravida enim, porta volutpat eros mauris ornare magna. Aliquam aliquet et enim ut vestibulum. Aliquam faucibus quis lacus sit amet vulputate. Aliquam scelerisque dignissim nisi, quis luctus nisi tempor nec. Vivamus laoreet magna felis, vitae tristique ante pharetra vel. Vestibulum non tempus lacus. Morbi ullamcorper velit id augue posuere ullamcorper. Integer facilisis condimentum ipsum vel dapibus. Cras porta libero ac velit tristique interdum. Donec commodo ornare neque. Nullam venenatis consequat nibh, eget facilisis elit faucibus vel. Donec facilisis libero purus, et ultricies urna maximus in. Nam a pretium eros, quis molestie augue.

Ut nec semper quam. In a nulla ornare, tempus lectus a, pulvinar mauris. Duis eu ullamcorper nisl. Ut ultricies ligula id lacus tincidunt, eget sagittis risus efficitur. Curabitur in ipsum quis sem elementum aliquet. Praesent mattis consequat neque sit amet facilisis. Proin tempus lorem eget purus ultrices volutpat at vel lectus. Fusce sed euismod tortor, blandit dictum nisi. Mauris placerat tellus vel pretium ornare. Aenean posuere libero nec diam aliquet pulvinar. Mauris diam augue, consequat vel risus ac, eleifend congue felis. Proin quis ipsum ante.

Sed lobortis nibh scelerisque est porta lobortis. Morbi et dolor at purus viverra fermentum. Duis at purus semper, gravida sem at, fermentum dolor. Mauris ut massa id elit condimentum efficitur. Maecenas a nisi nisi. Fusce tortor metus, efficitur id libero eu, dictum semper orci. Curabitur luctus nunc at justo vehicula imperdiet. Aliquam facilisis maximus ornare. Integer accumsan tincidunt ante quis euismod. Quisque dapibus ipsum eu enim ultricies hendrerit. Quisque ac convallis lorem, facilisis sagittis massa. Vestibulum eu mi lectus. Vestibulum ut congue nunc.

Ut faucibus sem a arcu ullamcorper, eget lacinia felis posuere. Cras suscipit lectus quis felis lacinia, accumsan feugiat quam semper. Phasellus consequat consequat risus, ac malesuada leo porttitor et. Etiam efficitur lectus orci, a molestie nunc laoreet non. Vestibulum non ultrices mauris. Ut libero diam, egestas eget metus in, auctor fringilla urna. Aliquam nec velit euismod, blandit lorem eget, pharetra mi. Aliquam id varius turpis. Pellentesque ornare ante malesuada felis gravida, dictum iaculis magna condimentum. Sed at tellus eget dolor imperdiet hendrerit et in mauris. Proin rhoncus consectetur ante, nec condimentum leo. Vestibulum efficitur turpis vehicula mattis posuere. Cras orci dolor, rutrum id auctor a, ultricies a mauris. Phasellus risus quam, euismod non nibh id, imperdiet feugiat velit. Suspendisse feugiat blandit eros, vel condimentum nunc porta eu.

Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. Ut volutpat ante ut nulla condimentum, sed sollicitudin ligula lacinia. Aliquam sapien est, maximus in feugiat et, tincidunt vitae mauris. Vestibulum vel luctus ex. Nam augue urna, accumsan nec convallis quis, scelerisque ac enim. Proin feugiat nunc convallis nibh gravida, non rhoncus lectus porta. Curabitur laoreet urna sapien, et maximus tellus feugiat non. Proin vitae volutpat augue. Curabitur tincidunt mi augue, et accumsan nisi elementum vel. Quisque faucibus facilisis enim. Morbi tincidunt ligula ac sollicitudin venenatis. Fusce et viverra quam. Duis eget elit sed justo rutrum malesuada at ultricies tortor. Phasellus rhoncus enim sit amet justo aliquam mattis. Sed vel mi nec mauris cursus cursus sed non purus.
"""

# ╔═╡ c34ba591-38fb-4b2b-83ba-b8940edb71af
length(s)

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
BangBang = "198e06fe-97b7-11e9-32a5-e1d131e6ad66"
BenchmarkTools = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
MicroCollections = "128add7d-3638-4c79-886c-908ea0c25c34"
PlutoTest = "cb4044da-4d16-4ffa-a6a3-8cad7f73ebdc"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
StaticArrays = "90137ffa-7385-5640-81b9-e52037218182"
Transducers = "28d57a85-8fef-5791-bfe6-a80928e7c999"
Tullio = "bc48ee85-29a4-5162-ae0b-a64e1601d4bc"

[compat]
BangBang = "~0.3.32"
BenchmarkTools = "~1.2.0"
MicroCollections = "~0.1.1"
PlutoTest = "~0.1.2"
PlutoUI = "~0.7.16"
StaticArrays = "~1.2.13"
Transducers = "~0.4.66"
Tullio = "~0.3.2"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

[[Adapt]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "84918055d15b3114ede17ac6a7182f68870c16f7"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "3.3.1"

[[ArgCheck]]
git-tree-sha1 = "dedbbb2ddb876f899585c4ec4433265e3017215a"
uuid = "dce04be8-c92d-5529-be00-80e4d2c0e197"
version = "2.1.0"

[[ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"

[[Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[BangBang]]
deps = ["Compat", "ConstructionBase", "Future", "InitialValues", "LinearAlgebra", "Requires", "Setfield", "Tables", "ZygoteRules"]
git-tree-sha1 = "0ad226aa72d8671f20d0316e03028f0ba1624307"
uuid = "198e06fe-97b7-11e9-32a5-e1d131e6ad66"
version = "0.3.32"

[[Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[Baselet]]
git-tree-sha1 = "aebf55e6d7795e02ca500a689d326ac979aaf89e"
uuid = "9718e550-a3fa-408a-8086-8db961cd8217"
version = "0.1.1"

[[BenchmarkTools]]
deps = ["JSON", "Logging", "Printf", "Profile", "Statistics", "UUIDs"]
git-tree-sha1 = "61adeb0823084487000600ef8b1c00cc2474cd47"
uuid = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
version = "1.2.0"

[[ChainRulesCore]]
deps = ["Compat", "LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "d9e40e3e370ee56c5b57e0db651d8f92bce98fea"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.10.1"

[[Compat]]
deps = ["Base64", "Dates", "DelimitedFiles", "Distributed", "InteractiveUtils", "LibGit2", "Libdl", "LinearAlgebra", "Markdown", "Mmap", "Pkg", "Printf", "REPL", "Random", "SHA", "Serialization", "SharedArrays", "Sockets", "SparseArrays", "Statistics", "Test", "UUIDs", "Unicode"]
git-tree-sha1 = "31d0151f5716b655421d9d75b7fa74cc4e744df2"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "3.39.0"

[[CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"

[[CompositionsBase]]
git-tree-sha1 = "455419f7e328a1a2493cabc6428d79e951349769"
uuid = "a33af91c-f02d-484b-be07-31d278c5ca2b"
version = "0.1.1"

[[ConstructionBase]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "f74e9d5388b8620b4cee35d4c5a618dd4dc547f4"
uuid = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
version = "1.3.0"

[[DataAPI]]
git-tree-sha1 = "cc70b17275652eb47bc9e5f81635981f13cea5c8"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.9.0"

[[DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[DefineSingletons]]
git-tree-sha1 = "77b4ca280084423b728662fe040e5ff8819347c5"
uuid = "244e2a9f-e319-4986-a169-4d1fe445cd52"
version = "0.1.1"

[[DelimitedFiles]]
deps = ["Mmap"]
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"

[[DiffRules]]
deps = ["NaNMath", "Random", "SpecialFunctions"]
git-tree-sha1 = "7220bc21c33e990c14f4a9a319b1d242ebc5b269"
uuid = "b552c78f-8df3-52c6-915a-8e097449b14b"
version = "1.3.1"

[[Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "a32185f5428d3986f47c2ab78b1f216d5e6cc96f"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.8.5"

[[Downloads]]
deps = ["ArgTools", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"

[[Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "8d511d5b81240fc8e6802386302675bdf47737b9"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.4"

[[HypertextLiteral]]
git-tree-sha1 = "f6532909bf3d40b308a0f360b6a0e626c0e263a8"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.1"

[[IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "f7be53659ab06ddc986428d3a9dcc95f6fa6705a"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.2"

[[InitialValues]]
git-tree-sha1 = "7f6a4508b4a6f46db5ccd9799a3fc71ef5cad6e6"
uuid = "22cec73e-a1b8-11e9-2c92-598750a2cf9c"
version = "0.2.11"

[[InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[InverseFunctions]]
deps = ["Test"]
git-tree-sha1 = "f0c6489b12d28fb4c2103073ec7452f3423bd308"
uuid = "3587e190-3f89-42d0-90ee-14403ec27112"
version = "0.1.1"

[[IrrationalConstants]]
git-tree-sha1 = "7fd44fd4ff43fc60815f8e764c0f352b83c49151"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.1.1"

[[IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "642a199af8b68253517b80bd3bfd17eb4e84df6e"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.3.0"

[[JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "8076680b162ada2a031f707ac7b4953e30667a37"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.2"

[[LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"

[[LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"

[[LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"

[[Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[LinearAlgebra]]
deps = ["Libdl"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[LogExpFunctions]]
deps = ["ChainRulesCore", "DocStringExtensions", "InverseFunctions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "6193c3815f13ba1b78a51ce391db8be016ae9214"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.4"

[[Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "5a5bc6bf062f0f95e62d0fe0a2d99699fed82dd9"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.8"

[[Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"

[[MicroCollections]]
deps = ["BangBang", "Setfield"]
git-tree-sha1 = "4f65bdbbe93475f6ff9ea6969b21532f88d359be"
uuid = "128add7d-3638-4c79-886c-908ea0c25c34"
version = "0.1.1"

[[Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"

[[NaNMath]]
git-tree-sha1 = "bfe47e760d60b82b66b61d2d44128b62e3a369fb"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "0.3.5"

[[NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"

[[OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"

[[OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[Parsers]]
deps = ["Dates"]
git-tree-sha1 = "98f59ff3639b3d9485a03a72f3ab35bab9465720"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.0.6"

[[Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"

[[PlutoTest]]
deps = ["HypertextLiteral", "InteractiveUtils", "Markdown", "Test"]
git-tree-sha1 = "b7da10d62c1ffebd37d4af8d93ee0003e9248452"
uuid = "cb4044da-4d16-4ffa-a6a3-8cad7f73ebdc"
version = "0.1.2"

[[PlutoUI]]
deps = ["Base64", "Dates", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "Markdown", "Random", "Reexport", "UUIDs"]
git-tree-sha1 = "4c8a7d080daca18545c56f1cac28710c362478f3"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.16"

[[Preferences]]
deps = ["TOML"]
git-tree-sha1 = "00cfd92944ca9c760982747e9a1d0d5d86ab1e5a"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.2.2"

[[Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[Profile]]
deps = ["Printf"]
uuid = "9abbd945-dff8-562f-b5e8-e1ebf5ef1b79"

[[REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[Random]]
deps = ["Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "4036a3bd08ac7e968e27c203d45f5fff15020621"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.1.3"

[[SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"

[[Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[Setfield]]
deps = ["ConstructionBase", "Future", "MacroTools", "Requires"]
git-tree-sha1 = "def0718ddbabeb5476e51e5a43609bee889f285d"
uuid = "efcf1570-3423-57d1-acb7-fd33fddbac46"
version = "0.8.0"

[[SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[SpecialFunctions]]
deps = ["ChainRulesCore", "IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "2d57e14cd614083f132b6224874296287bfa3979"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "1.8.0"

[[SplittablesBase]]
deps = ["Setfield", "Test"]
git-tree-sha1 = "39c9f91521de844bad65049efd4f9223e7ed43f9"
uuid = "171d559e-b47b-412a-8079-5efa626c420e"
version = "0.1.14"

[[StaticArrays]]
deps = ["LinearAlgebra", "Random", "Statistics"]
git-tree-sha1 = "3c76dde64d03699e074ac02eb2e8ba8254d428da"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.2.13"

[[Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"

[[TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "TableTraits", "Test"]
git-tree-sha1 = "fed34d0e71b91734bf0a7e10eb1bb05296ddbcd0"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.6.0"

[[Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"

[[Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[Transducers]]
deps = ["Adapt", "ArgCheck", "BangBang", "Baselet", "CompositionsBase", "DefineSingletons", "Distributed", "InitialValues", "Logging", "Markdown", "MicroCollections", "Requires", "Setfield", "SplittablesBase", "Tables"]
git-tree-sha1 = "dec7b7839f23efe21770b3b1307ca77c13ed631d"
uuid = "28d57a85-8fef-5791-bfe6-a80928e7c999"
version = "0.4.66"

[[Tullio]]
deps = ["ChainRulesCore", "DiffRules", "LinearAlgebra", "Requires"]
git-tree-sha1 = "0288b7a395fc412952baf756fac94e4f28bfec65"
uuid = "bc48ee85-29a4-5162-ae0b-a64e1601d4bc"
version = "0.3.2"

[[UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"

[[ZygoteRules]]
deps = ["MacroTools"]
git-tree-sha1 = "8c1a8e4dfacb1fd631745552c8db35d0deb09ea0"
uuid = "700de1a5-db45-46bc-99cf-38207098b444"
version = "0.2.2"

[[nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"

[[p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
"""

# ╔═╡ Cell order:
# ╠═1c4d22e2-4d58-401e-96b6-1745a3fe5209
# ╠═7e7204a6-2db7-11ec-0602-7590cdcd6c01
# ╠═72330b0d-3d19-4807-a099-2487ce38f3dc
# ╠═2442bcc7-2fb0-44ae-b0be-9528f8a51793
# ╠═329bbaa9-a90d-419d-86aa-9b2658f303f2
# ╠═5fbb9977-aac7-4c9a-b16d-fe5558d928cd
# ╠═ba173400-53c7-47b1-8d25-b9f4e0272ddb
# ╠═63f1e6d5-b29b-4206-b966-235a28cbccda
# ╠═00290cf2-1556-484b-b6e8-8bb02a81a392
# ╠═fc2611e0-94e1-4073-9ee0-f6ed09c3ad72
# ╠═f88de2fb-259f-40e7-848b-3d26a871c7a9
# ╠═2f3dca61-b71c-4d11-9b79-0db3dc130552
# ╠═13cf54c0-ee19-4057-b798-91f5ae7a5f69
# ╠═809eba0f-ef17-4a66-b604-37a2a3438e61
# ╠═3b3ee27a-63f4-4c01-952e-43f9308ef7f3
# ╠═13769317-d840-4851-8547-af08688877e0
# ╠═04b46d58-5157-41b6-8713-5c401432252f
# ╠═ae2355b2-9e62-4356-8a04-f99f8d01e27b
# ╠═525b0d59-e492-419e-9240-70d682dd9456
# ╠═268dbea8-4e6b-4fb9-ba7d-fc07372f96d0
# ╠═825126f5-e9b7-4c93-ae23-31517b297672
# ╠═cc5af8c3-6bce-4bba-b65d-022de74a8cb3
# ╠═4534b095-508a-4a53-a0ee-5283132c1809
# ╠═9929116d-7d18-4d60-a082-c00bdb4e7cf7
# ╠═b2c9a44d-3e98-4acf-8cc8-6fc2ee0208d7
# ╠═756c8c9f-0c4e-4009-9454-b1f28330b707
# ╠═83740467-22e0-41ea-bf51-00523f63f541
# ╠═fbaf8bdb-650d-4627-ad25-201352150778
# ╠═7cd8ac94-f88f-4728-9d51-a35339014fe2
# ╠═a662797b-69eb-451d-b206-113a84a261d0
# ╠═aa19e325-67be-4a2b-a8a0-96c1890e0c70
# ╠═9999d0be-3ec9-4875-bea3-a0884b7d63fe
# ╠═46767ba5-a002-4176-bd86-38310c49bc07
# ╠═59f3189f-983e-4b81-acbf-76773c81f9c8
# ╠═2711c17f-a8c7-4a3a-8eeb-175a1b0b1292
# ╠═5b2904ef-0516-4c83-a670-b05c7a3a800c
# ╠═90187e2e-36ec-4930-8ff2-905e9916564f
# ╠═60ba2c19-8b7a-44c5-9236-a264df831828
# ╠═55afcd00-0a5f-4ab8-9b30-7e550d0d21dd
# ╠═bb099473-a2c7-4b55-a51c-f45a0c63c979
# ╠═f7110269-0599-4b2e-8b93-c877a753f1db
# ╠═bb42fe13-4663-4c79-b66d-1c69ed14090c
# ╠═6942bc7d-0a37-413e-9a81-09eeb25cc433
# ╠═c34ba591-38fb-4b2b-83ba-b8940edb71af
# ╟─d45787c6-2a38-474f-994d-50d09d338786
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
