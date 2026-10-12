# API Explorer interview guide

## Architecture decisions

1. **One repository, two cubits.** `CatalogCubit` pages the list. `ProductDetailCubit` loads one id. They share `ProductRepository`, not each other's state.

2. **Typed failures.** `mapDioException` turns Dio's timeout, connection, and status codes into `ApiFailure`. JSON problems become `ApiFailureKind.malformed`. The page shows `failure.message`, not `error.toString()`.

3. **A failed next page keeps the first page.** `loadMore` returns the message and leaves `status` at `ready`. A failed first load sets `CatalogStatus.failure`.

4. **Generation counter.** `load` increments `_generation`. When the response arrives, the cubit emits only if the generation still matches. A slow search cannot overwrite a newer one.

5. **GetIt at the edge.** `main` registers `DioProductRepository`. The widget tree receives the repository through `RepositoryProvider`. Tests skip GetIt.

## Questions

**Why DummyJSON?**
It is a public catalog with list, search, and detail, and it does not need a key. On 12 October 2026 those three URLs returned HTTP 200. The tests still use a fake adapter so CI does not depend on that site.

**What is logged?**
Method, URL path, and status code or Dio error type. Not headers, not the body, not the query string.

**How does pagination know when to stop?**
`hasMore` is `products.length < total`. The total comes from DummyJSON's `total` field. The page size defaults to 20.

**Why can detail and list disagree?**
Detail fetches `/products/{id}` again. If the list JSON and the detail JSON ever differed, the screen would show the detail response. Caching the list row would avoid the extra call. That cache is not implemented.

**What does a 404 on the list mean versus the detail?**
Both map to `That product was not found.` A 5xx maps to `The product service returned an error.`

## A hard bug, and the fix

Appending the next page and then emitting an error state used to be the easy mistake, because one `CatalogState` was doing both jobs.

`loadMore` now updates `isLoadingMore` and, on `ApiFailure`, leaves `products` untouched. The repository test `load more keeps products when the next page fails` covers it.

## Error handling

| Situation | Result |
| --- | --- |
| Connect, send, or receive timeout | `The request timed out.` |
| Connection error | `You appear to be offline.` |
| HTTP 404 | `That product was not found.` |
| HTTP 5xx | `The product service returned an error.` |
| Missing `products` list or required product fields | `The product service returned data this app could not read.` |
| Empty `products` with a valid page | Ready state and `No products match this search.` |

## Testing

- Mapper tests construct `DioException` values. They do not open a socket.
- Repository tests use a scripted `HttpClientAdapter`.
- Cubit test uses an in-memory `ProductRepository`.
- Widget tests cover the list, an empty search, retry, and navigation to the description.

## Trade-offs

- No search debounce, so the request rate is obvious and testable.
- No image cache.
- Live DummyJSON is a dependency of `flutter run`, not of `flutter test`.

## What would change in production

- A base URL from configuration, still without committing secrets
- Auth headers added in one interceptor, with tests that they are not logged
- Certificate pinning only if the API owner requires it
- Pagination cursor if the API stopped sending `total`
- A device run against the real API and screenshots of the loaded list
