
#include <iterator>
#include <array>
#include <cstddef>
#include <cxxabi.h>
#include <iostream>

template <typename T>
using remove_cvref = std::remove_cv_t<std::remove_reference_t<T>>;

template <typename T, T... values>
struct Seq {
    constexpr const static auto as_array = {values...};
    constexpr const static auto size = sizeof...(values);

    template <T value>
    using push_front = Seq<T, value, values...>;

    template <T value>
    using push_back = Seq<T, values..., value>;

    template <size_t index>
    constexpr const static auto get = as_array[index];
};

namespace seq {
    template <auto array, size_t... indices>
    using gather = Seq<remove_cvref<decltype(array[0])>, array[indices]...>;


    template <auto array, typename Indices>
    struct FromArrayImpl;

    template <auto array, size_t... indices>
    struct FromArrayImpl<array, std::index_sequence<indices...>> {
        using type = gather<array, indices...>;
    };

    template <auto array>
    using from_array = typename FromArrayImpl<array, std::make_index_sequence<std::size(array) - 1>>::type;


    template <typename Seq>
    struct HeadImpl;

    template <typename T, T head, T... values>
    struct HeadImpl<Seq<T, head, values...>> {
        constexpr const static auto value = head;
    };

    template <typename Seq>
    constexpr const auto head = HeadImpl<Seq>::value;


    template <typename Seq>
    struct TailImpl;

    template <typename T, T head, T... values>
    struct TailImpl<Seq<T, head, values...>> {
        using type = Seq<T, values...>;
    };

    template <typename Seq>
    using tail = typename TailImpl<Seq>::type;
}

template <char... values>
using Str = Seq<char, values...>;

namespace str {
    template <typename Str, char delim>
    struct SubstrDelimImpl;

    template <char head, char... tail, char delim>
    struct SubstrDelimImpl<Str<head, tail...>, delim> {
        using type = typename SubstrDelimImpl<Str<tail...>, delim>::type::template push_front<head>;
        using remainder = typename SubstrDelimImpl<Str<tail...>, delim>::remainder;
    };

    template <char... tail, char delim>
    struct SubstrDelimImpl<Str<delim, tail...>, delim> {
        using type = Str<>;
        using remainder = Str<tail...>;
    };

    template <char delim>
    struct SubstrDelimImpl<Str<>, delim> {
        using type = Str<>;
        using remainder = Str<>;
    };

    template <typename Str, char delim>
    using substr_delim = typename SubstrDelimImpl<Str, delim>::type;


    template <typename Str, size_t acc>
    struct ParseIntImpl;

    template <char head, char... tail, size_t acc>
    struct ParseIntImpl<Str<head, tail...>, acc> {
        constexpr const static size_t value = ParseIntImpl<Str<tail...>, acc * 10 + head - '0'>::value;
    };

    template <size_t acc>
    struct ParseIntImpl<Str<>, acc> {
        constexpr const static size_t value = acc;
    };

    template <typename Str>
    constexpr const static size_t parse_int = ParseIntImpl<Str, 0>::value;
}

template <typename... Ts>
struct List {
    constexpr const static size_t size = sizeof...(Ts);

    template <typename T>
    using push_front = List<T, Ts...>;

    template <typename T>
    using push_back = List<Ts..., T>;
};

namespace list {
    template <typename Str, char delim>
    struct SplitImpl;

    template <char... tail, char delim>
    struct SplitImpl<Str<tail...>, delim> {
        using item = str::SubstrDelimImpl<Str<tail...>, delim>;
        using type = typename SplitImpl<typename item::remainder, delim>::type::template push_front<typename item::type>;
    };

    template <char delim>
    struct SplitImpl<Str<>, delim> {
        using type = List<>;
    };

    template <char delim>
    struct SplitImpl<Str<delim>, delim> {
        using type = List<>;
    };

    template <typename Str, char delim>
    using split = typename SplitImpl<Str, delim>::type;


    template <typename List, size_t index>
    struct GetImpl;

    template <typename Head, typename... Tail, size_t index>
    struct GetImpl<List<Head, Tail...>, index> {
        using type = typename GetImpl<List<Tail...>, index - 1>::type;
    };

    template <typename Head, typename... Tail>
    struct GetImpl<List<Head, Tail...>, 0> {
        using type = Head;
    };

    template <typename List, size_t index>
    using get = typename GetImpl<List, index>::type;


    template <typename List>
    struct HeadImpl;

    template <typename Head, typename... Tail>
    struct HeadImpl<List<Head, Tail...>> {
        using type = Head;
    };

    template <typename List>
    using head = typename HeadImpl<List>::type;


    template <typename List>
    struct TailImpl;

    template <typename Head, typename... Tail>
    struct TailImpl<List<Head, Tail...>> {
        using type = List<Tail...>;
    };

    template <typename List>
    using tail = typename TailImpl<List>::type;


    template <typename List, template <typename> typename F>
    struct MapImpl;

    template <typename Head, typename... Tail, template <typename> typename F>
    struct MapImpl<List<Head, Tail...>, F> {
        using type = typename MapImpl<List<Tail...>, F>::type::template push_front<F<Head>>;
    };

    template <template <typename> typename F>
    struct MapImpl<List<>, F> {
        using type = List<>;
    };

    template <typename List, template <typename> typename F>
    using map = typename MapImpl<List, F>::type;


    template <typename List, template <typename> typename F>
    struct FilterImpl;

    template <typename Head, typename... Tail, template <typename> typename F>
    struct FilterImpl<List<Head, Tail...>, F> {
        using rest = typename FilterImpl<List<Tail...>, F>::type;
        using rest_with = rest::template push_front<Head>;

        using type = std::conditional_t<
                F<Head>::value,
                rest_with,
                rest
            >;
    };

    template <template <typename> typename F>
    struct FilterImpl<List<>, F> {
        using type = List<>;
    };

    template <typename List, template <typename> typename F>
    using filter = typename FilterImpl<List, F>::type;


    template <typename List1, typename List2>
    struct ConcatImpl;

    template <typename... Items1, typename... Items2>
    struct ConcatImpl<List<Items1...>, List<Items2...>> {
        using type = List<Items1..., Items2...>;
    };

    template <typename List1, typename List2>
    using concat = typename ConcatImpl<List1, List2>::type;
}

template <int x_component, int y_component>
struct Vec {
    constexpr const static auto x = x_component;
    constexpr const static auto y = y_component;

    template <int amount>
    using scale = Vec<x * amount, y * amount>;

    template <typename Other>
    using add = Vec<x + Other::x, y + Other::y>;

    template <typename Other>
    using min = Vec<std::min(x, Other::x), std::min(y, Other::y)>;

    template <typename Other>
    using max = Vec<std::max(x, Other::x), std::max(y, Other::y)>;

    constexpr const static auto manhattan = std::abs(x) + std::abs(y);
};

enum class Direction {
    Up, Down, Left, Right
};

namespace direction {
    template <char c>
    struct ParseImpl;

    template <>
    struct ParseImpl<'U'> {
        constexpr const static auto value = Direction::Up;
    };

    template <>
    struct ParseImpl<'D'> {
        constexpr const static auto value = Direction::Down;
    };

    template <>
    struct ParseImpl<'L'> {
        constexpr const static auto value = Direction::Left;
    };

    template <>
    struct ParseImpl<'R'> {
        constexpr const static auto value = Direction::Right;
    };

    template <char c>
    constexpr const auto parse = ParseImpl<c>::value;

    template <Direction dir>
    using to_offset = list::get<
            List<
                Vec<0, 1>, // up
                Vec<0, -1>, // down
                Vec<-1, 0>, // left
                Vec<1, 0> // right
            >,
            static_cast<size_t>(dir)
        >;
}

template <Direction dir, size_t ln>
struct Segment {
    constexpr const static auto direction = dir;
    constexpr const static auto length = ln;
};

namespace {
    template <typename Str>
    using parse_segment = Segment<
            direction::parse<seq::head<Str>>,
            str::parse_int<seq::tail<Str>>
        >;

    template <typename Str>
    using parse_segments = list::map<
            list::split<Str, ','>,
            parse_segment
        >;
}

template <Direction dir, typename start_pos, int size>
struct Line {
    constexpr const static auto direction = dir;
    constexpr const static auto length = size;

    using a = start_pos;
    using b = direction::to_offset<direction>::template scale<length>::template add<start_pos>;

    using start = typename a::template min<b>;
    using end = typename a::template max<b>;

    constexpr const static auto horizontal = direction == Direction::Left || direction == Direction::Right;
};

namespace line {
    template <typename SegmentList, typename Pos>
    struct SegmentsToLinesImpl;

    template <typename Head, typename... Tail, typename Pos>
    struct SegmentsToLinesImpl<List<Head, Tail...>, Pos> {
        using line = Line<Head::direction, Pos, Head::length>;
        using type = SegmentsToLinesImpl<List<Tail...>, typename line::b>::type::template push_front<line>;
    };

    template <typename Pos>
    struct SegmentsToLinesImpl<List<>, Pos> {
        using type = List<>;
    };

    template <typename Lines>
    using segments_to_lines = typename SegmentsToLinesImpl<Lines, Vec<0, 0>>::type;

    template <typename Horizontal, typename Vertical>
    constexpr const auto intersects_hv =
        (Horizontal::start::x <= Vertical::start::x && Vertical::start::x < Horizontal::end::x) &&
        (Vertical::start::y <= Horizontal::start::y && Horizontal::start::y < Vertical::end::y);

    template <typename Horizontal, typename Vertical>
    using intersection_hv = std::conditional_t<
            intersects_hv<Horizontal, Vertical>,
            Vec<Vertical::start::x, Horizontal::start::y>,
            void
        >;

    template <typename Line1, typename Line2>
    using intersection = std::conditional_t<
            Line1::horizontal == Line2::horizontal,
            void, // dont care about the cases where the lines are parallel
            std::conditional_t<
                Line1::horizontal,
                intersection_hv<Line1, Line2>,
                intersection_hv<Line2, Line1>
            >
        >;

    template <typename Lines1, typename Lines2>
    struct IntersectionsImpl;

    template <typename Head, typename... Tail, typename Lines2>
    struct IntersectionsImpl<List<Head, Tail...>, Lines2> {
        using rest = typename IntersectionsImpl<List<Tail...>, Lines2>::type;

        template <typename Line>
        using intersection_with_head = intersection<Head, Line>;

        using intersections_with_head =
            list::filter<
                list::map<Lines2, intersection_with_head>,
                std::is_class
            >;

        using type = list::concat<intersections_with_head, rest>;
    };

    template <typename Lines2>
    struct IntersectionsImpl<List<>, Lines2> {
        using type = List<>;
    };

    template <typename Lines1, typename Lines2>
    using intersections = typename IntersectionsImpl<Lines1, Lines2>::type;
}

template <typename Intersections>
struct SelectLowestManhattanImpl;

template <typename Head, typename... Tail>
struct SelectLowestManhattanImpl<List<Head, Tail...>> {
    using prev = typename SelectLowestManhattanImpl<List<Tail...>>::type;

    using type = std::conditional_t<
            (Head::manhattan < prev::manhattan),
            Head,
            prev
        >;
};

template <>
struct SelectLowestManhattanImpl<List<>> {
    using type = Vec<99999, 99999>;
};

template <typename Intersections>
using select_lowest_manhattan = typename SelectLowestManhattanImpl<Intersections>::type;

template <size_t N>
constexpr std::array<char, N> to_array(const char (&from)[N]) {
    auto to = std::array<char, N>{};
    for (size_t i = 0; i < N; ++i) {
        to[i] = from[i];
    }

    return to;
}

constexpr const char input_text[] =
    "R75,D30,R83,U83,L12,D49,R71,U7,L72\n"
    "U62,R66,U55,R34,D71,R55,D58,R83";

// constexpr const char input_text[] =
//     "R8,U5,L5,D3\n"
//     "U7,R6,D4,L4";

int main() {
    using input = seq::from_array<to_array(input_text)>;

    using line_inputs = list::split<input, '\n'>;
    using segments = list::map<
            line_inputs,
            parse_segments
        >;

    using lines1 = line::segments_to_lines<list::head<segments>>;
    using lines2 = line::segments_to_lines<list::head<list::tail<segments>>>;

    using intersections = line::intersections<lines1, lines2>;
    using lowest = select_lowest_manhattan<list::tail<intersections>>;

    int a = Seq<int, lowest::manhattan>{};

    return 0;
}