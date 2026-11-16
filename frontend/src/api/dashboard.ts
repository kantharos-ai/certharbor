import { getDashboardOptions } from '@kantharos-net/certharbor-client/react-query'
import { useQuery } from '@tanstack/react-query'

// No params: the dashboard is a page-shaped aggregate (D10), not a list.
export function useDashboard() {
  return useQuery(getDashboardOptions())
}
