// moderngpu copyright (c) 2016, Sean Baxter http://www.moderngpu.com
#pragma once
#include "cta_load_balance.hxx"
#include "search.hxx"

BEGIN_MGPU_NAMESPACE

template<typename launch_arg_t = empty_t, typename func_t, 
  typename segments_it, typename tpl_t>
void transform_lbs(func_t f, int count, segments_it segments, 
  int num_segments, tpl_t caching_iterators, context_t& context) {

  typedef typename conditional_typedef_t<launch_arg_t, 
    launch_box_t<
      arch_20_cta<128, 11, 8>,
      arch_35_cta<128,  7, 5>,
      arch_52_cta<128, 11, 8>
    >
  >::type_t launch_t;

  typedef typename std::iterator_traits<segments_it>::value_type int_t;
  typedef typename tuple_iterator_value_t<tpl_t>::type_t value_t;

  mem_t<int_t> mp = load_balance_partitions(count, segments, num_segments,
    launch_t::nv(context), context);
  const int_t* mp_data = mp.data();

  auto k = [=]MGPU_DEVICE(int tid, int cta) {
    typedef typename launch_t::sm_ptx params_t;
    enum { nt = params_t::nt, vt = params_t::vt, vt0 = params_t::vt0 };
    typedef cta_load_balance_t<nt, vt> load_balance_t;
    typedef detail::cached_segment_load_t<0, nt, vt, tpl_t> cached_load_t;

    __shared__ union {
      typename load_balance_t::storage_t lbs;
      typename cached_load_t::storage_t cached;
    } shared;

    // Compute the load-balancing search and materialize (index, seg, rank)
    // arrays.
    auto lbs = load_balance_t().load_balance(count, segments, num_segments,
      tid, cta, mp_data, shared.lbs);

    // Load from the cached iterators. Use the placement range, not the 
    // merge-path range for situating the segments.
    array_t<value_t, vt> cached_values;
    cached_load_t::load(tid, lbs.placement.range.b_range(), lbs.segments, 
      shared.cached, caching_iterators, cached_values);

    // Call the user-supplied functor f.
    strided_iterate<nt, vt, vt0>([=](int i, int j) {
      int index = lbs.merge_range.a_begin + j;
      int seg = lbs.segments[i];
      int rank = lbs.ranks[i];

      f(index, seg, rank, cached_values[i]);
    }, tid, lbs.merge_range.a_count());
  };
  cta_transform<launch_t>(k, count + num_segments, context);
}

// load-balancing search without caching.
template<typename launch_arg_t = empty_t, typename func_t, 
  typename segments_it>
void transform_lbs(func_t f, int count, segments_it segments, 
  int num_segments, context_t& context) {

  transform_lbs<launch_arg_t>(
    [=]MGPU_DEVICE(int index, int seg, int rank, tuple<>) {
      f(index, seg, rank);    // drop the cached values.
    },
    count, segments, num_segments, tuple<>(), context
  );
}

template<typename segments_it>
mem_t<int> load_balance_search(int count, segments_it segments, 
  int num_segments, context_t& context) {

  mem_t<int> lbs(count, context);
  int* lbs_data = lbs.data();

  transform_lbs([=]MGPU_DEVICE(int index, int seg, int rank) {
    lbs_data[index] = seg;
  }, count, segments, num_segments, context);

  return lbs;
}

END_MGPU_NAMESPACE
