// -----------------------------------------------------------------------------------------------------
// Copyright (c) 2006-2020, Knut Reinert & Freie Universität Berlin
// Copyright (c) 2016-2020, Knut Reinert & MPI für molekulare Genetik
// This file may be used, modified and/or redistributed under the terms of the 3-clause BSD-License
// shipped with this file and also available at: https://github.com/seqan/seqan3/blob/master/LICENSE.md
// -----------------------------------------------------------------------------------------------------

#include <gtest/gtest.h>

#include <fstream>
#include <iostream>
#include <string>

#include <seqan3/test/tmp_filename.hpp>
#include <seqan3/utility/tag.hpp>

#include <bio/stream/compression.hpp>
#include <bio/stream/detail/make_stream.hpp>

#include "data.hpp"

template <bio::compression_format f, typename stream_t = typename bio::detail::compression_stream<f>::istream>
void regular()
{
    seqan3::test::tmp_filename filename{"istream_test"};

    {
        std::ofstream fi{filename.get_path()};

        fi << compressed<f>;
    }

    std::ifstream fi{filename.get_path(), std::ios::binary};
    stream_t comp{fi};
    std::string buffer{std::istreambuf_iterator<char>{comp}, std::istreambuf_iterator<char>{}};

    EXPECT_EQ(buffer, uncompressed);
}

template <bio::compression_format f, typename stream_t = typename bio::detail::compression_stream<f>::istream>
void type_erased()
{
    seqan3::test::tmp_filename filename{"istream_test"};

    {
        std::ofstream fi{filename.get_path()};

        fi << compressed<f>;
    }

    std::ifstream fi{filename.get_path(), std::ios::binary};
    std::unique_ptr<std::istream> comp{new stream_t{fi}};
    std::string buffer{std::istreambuf_iterator<char>{*comp}, std::istreambuf_iterator<char>{}};

    EXPECT_EQ(buffer, uncompressed);
}