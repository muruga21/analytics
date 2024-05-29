import React from 'react';
import * as api from '../../api'
import * as url from '../../util/url'

import { CR_METRIC } from '../reports/metrics';
import ListReport from '../reports/list';

export default function Conversions(props) {
  const { site, query, afterFetchData } = props

  function fetchConversions() {
    return api.get(url.apiPath(site, '/conversions'), query, { limit: 9 })
  }

  function getFilterFor(listItem) {
    return {
      prefix: "goal",
      filter: ["is", "goal", [listItem.name]],
    }
  }

  /*global BUILD_EXTRA*/
  return (
    <ListReport
      fetchData={fetchConversions}
      afterFetchData={afterFetchData}
      getFilterFor={getFilterFor}
      keyLabel="Goal"
      onClick={props.onGoalFilterClick}
      metrics={[
        { name: 'visitors', label: "Uniques", plot: true },
        { name: 'events', label: "Total", hiddenOnMobile: true },
        CR_METRIC,
        BUILD_EXTRA && { name: 'total_revenue', label: 'Revenue', hiddenOnMobile: true },
        BUILD_EXTRA && { name: 'average_revenue', label: 'Average', hiddenOnMobile: true }
      ]}
      detailsLink={url.sitePath(site, '/conversions')}
      maybeHideDetails={true}
      query={query}
      color="bg-red-50"
      colMinWidth={90}
    />
  )
}
