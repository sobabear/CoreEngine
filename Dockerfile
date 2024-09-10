
FROM swift:5.8 as build

WORKDIR /app

COPY Package.swift .
COPY .swiftpm .
COPY Sources ./Sources
COPY Assets ./Assets


RUN swift package resolve
RUN swift build -c release

FROM swift:5.8-slim

WORKDIR /app

COPY --from=build /app/.build/release/CoreEngine /app/

CMD ["./CoreEngine"]
