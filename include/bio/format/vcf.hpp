// -----------------------------------------------------------------------------------------------------
// Copyright (c) 2006-2021, Knut Reinert & Freie Universität Berlin
// Copyright (c) 2016-2021, Knut Reinert & MPI für molekulare Genetik
// Copyright (c) 2020-2021, deCODE Genetics
// This file may be used, modified and/or redistributed under the terms of the 3-clause BSD-License
// shipped with this file and also available at: https://github.com/seqan/seqan3/blob/master/LICENSE.md
// -----------------------------------------------------------------------------------------------------

/*!\file
 * \brief Provides the bio::vcf.
 * \author Hannes Hauswedell <hannes.hauswedell AT decode.is>
 */

#pragma once

#include <ranges>

#include <bio/platform.hpp>

namespace bio
{

//!\brief The VCF file format tag.
struct vcf
{
    //!\brief The valid file extensions for this format; note that you can modify this value.
    static inline std::vector<std::string> file_extensions{{"vcf"}};
};

} // namespace bio