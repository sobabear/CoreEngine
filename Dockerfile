
FROM swift:6.0 as build

WORKDIR /app

COPY Package.swift .
COPY .swiftpm .
COPY Sources ./Sources
COPY Tests ./Tests 

RUN swift package resolve
RUN swift build -c release
# RUN swift test --parallel
FROM swift:6.0-slim

WORKDIR /app

COPY --from=build /app/.build/release /app/build

CMD ["./CoreEngine"]
