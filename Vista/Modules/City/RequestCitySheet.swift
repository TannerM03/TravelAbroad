//
//  RequestCitySheet.swift
//  TravelAbroad
//
//  Created by Tanner Macpherson on 9/23/25.
//

import SwiftUI

struct RequestCitySheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var cityName: String = ""
    @State private var countryName: String = ""
    @FocusState private var focusedField: Field?
    @State private var showSuccessAlert = false

    var onSubmit: (String, String) -> Void

    enum Field {
        case city, country
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple.opacity(0.1), Color.blue.opacity(0.1), Color.clear]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 48))
                            .foregroundStyle(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.purple, Color.blue]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        Text("Request a City")
                            .font(.title2.weight(.bold))
                            .fontDesign(.rounded)

                        Text("Don't see your desired destination? Let us know and we'll add it!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 32)

                    VStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("City Name")
                                .font(.subheadline.weight(.semibold))
                                .fontDesign(.rounded)
                                .foregroundColor(.secondary)

                            TextField("e.g., Paris", text: $cityName)
                                .font(.body.weight(.medium))
                                .fontDesign(.rounded)
                                .padding(16)
                                .background(Color(.systemGray6).opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .focused($focusedField, equals: .city)
                                .submitLabel(.next)
                                .onSubmit {
                                    focusedField = .country
                                }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Country")
                                .font(.subheadline.weight(.semibold))
                                .fontDesign(.rounded)
                                .foregroundColor(.secondary)

                            TextField("e.g., France", text: $countryName)
                                .font(.body.weight(.medium))
                                .fontDesign(.rounded)
                                .padding(16)
                                .background(Color(.systemGray6).opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .focused($focusedField, equals: .country)
                                .submitLabel(.done)
                                .onSubmit {
                                    focusedField = nil
                                }
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer()

                    Button(action: submitRequest) {
                        HStack(spacing: 12) {
                            Image(systemName: "paperplane.fill")
                                .font(.title3.weight(.bold))
                                .foregroundColor(.white)

                            Text("Submit Request")
                                .font(.title3.weight(.bold))
                                .fontDesign(.rounded)
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.purple, Color.blue]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .purple.opacity(0.3), radius: 12, x: 0, y: 6)
                    }
                    .disabled(cityName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        countryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .opacity(cityName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                        countryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.5 : 1.0)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.secondary)
                }
            }
            .alert("Request Submitted!", isPresented: $showSuccessAlert) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Thanks for your suggestion! We'll review \(cityName), \(countryName) and add it soon.")
            }
        }
    }

    private func submitRequest() {
        let trimmedCity = cityName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCountry = countryName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedCity.isEmpty && !trimmedCountry.isEmpty else { return }

        onSubmit(trimmedCity, trimmedCountry)
        showSuccessAlert = true
    }
}

#Preview {
    RequestCitySheet { city, country in
        print("Requested: \(city), \(country)")
    }
}
