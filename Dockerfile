
FROM swift:5.8 as build

WORKDIR /app

COPY Package.swift .
COPY .swiftpm .
COPY Sources ./Sources
COPY Tests ./Tests 

RUN swift package resolve
RUN swift build -c release
# RUN swift test --parallel
FROM swift:5.8-slim

WORKDIR /app

COPY --from=build /app/.build/release /app/build

CMD ["./CoreEngine"]
