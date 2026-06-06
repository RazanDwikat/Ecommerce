# Ecommerce Flutter Frontend

Flutter frontend for the Node.js e-commerce backend, featuring a **product filter**
built with **Clean Architecture** + **Bloc/Cubit**.

## Backend filter contract

The filter mirrors `GET /products`, which accepts these query params:

| Param                 | Purpose                                      |
| --------------------- | -------------------------------------------- |
| `search`              | Name search (regex, case-insensitive)        |
| `category`            | Category id                                  |
| `minPrice` / `maxPrice` | Price range                                |
| `sort`                | e.g. `price`, `-price`, `-createdAt`         |
| `page` / `limit`      | Pagination                                   |

Response shape: `{ products, total, page, totalPages }`. Categories for the
dropdown come from `GET /categories`.

## Folder structure

```
lib/
├── core/                     # shared infrastructure
│   ├── network/              # ApiClient (Dio) + ApiEndpoints
│   ├── error/                # Failures & Exceptions
│   ├── usecases/             # base UseCase contract
│   └── di/                   # get_it dependency injection
│
├── features/
│   └── products/
│       ├── data/
│       │   ├── models/           # *_model.dart (JSON <-> entity)
│       │   ├── datasources/      # product_remote_datasource (builds query params)
│       │   └── repositories/     # product_repository_impl
│       ├── domain/
│       │   ├── entities/         # product, category, product_filter, paginated_products
│       │   ├── repositories/     # product_repository (abstract)
│       │   └── usecases/         # get_products, get_categories
│       └── presentation/
│           ├── manager/          # products_cubit + filter_cubit
│           ├── pages/            # products_page
│           └── widgets/          # search_field, category_dropdown, price_range_slider,
│                                 # sort_dropdown, filter_bottom_sheet, product_card
│
├── shared/
│   ├── widgets/              # loading / error / empty states
│   └── theme/               # app_theme
└── main.dart
```

### How the filter flows

1. User changes a control (`search_field` / `filter_bottom_sheet`).
2. `FilterCubit` updates the `ProductFilter` entity.
3. `ProductsPage` listens and calls the `GetProducts` use case.
4. `ProductRepository` → `ProductRemoteDataSource` turns the `ProductFilter`
   into query params (`ProductFilter.toQueryParameters()`) and hits `/products`.
5. The `{ products, total, page, totalPages }` response is parsed into
   `PaginatedProducts` and rendered.

## Running

```bash
flutter pub get

# Android emulator (backend on host :3000 -> 10.0.2.2)
flutter run

# Other targets / custom backend URL
flutter run --dart-define=BASE_URL=http://localhost:3000
```

## Tests

```bash
flutter test      # unit tests for ProductFilter -> query params
flutter analyze
```
