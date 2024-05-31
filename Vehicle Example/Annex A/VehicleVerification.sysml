package VehicleVerification {
    import VehicleConfigurations::VehicleConfiguration_b::**;
    import VerificationCaseDefinitions::*;
    import VerificationCases1::*;
    // the following is a model library which contains VerdictKind
    import VerificationCases::*;
    import VerificationSystem::*;
    package VerificationCaseDefinitions{
        verification def MassTest;
        verification def AccelerationTest;
        verification def ReliabilityTest;
    }
    package VerificationCases1{
        verification massTests:MassTest {
            subject vehicle_uut :> vehicle_b;
            actor vehicleVerificationSubSystem_1 = verificationContext.massVerificationSystem;
            objective {
                verify vehicleSpecification.vehicleMassRequirement{
                    redefines massActual=weighVehicle.massMeasured;
                }
            }     
            // method kinds are test, demo, analyze, should also include inspection, similarity
            @ VerificationMethod{
                kind = (VerificationMethodKind::test, VerificationMethodKind::analyze);
            }
            action weighVehicle {
                out massMeasured:>ISQ::mass;
            }
            then action evaluatePassFail {
                in massMeasured:>ISQ::mass;
                out verdict = PassIf(vehicleSpecification.vehicleMassRequirement(vehicle_uut));
            }
            flow from weighVehicle.massMeasured to evaluatePassFail.massMeasured;
            return :>> verdict = evaluatePassFail.verdict;
        }
    }
    package VerificationSystem{
        part verificationContext{
            perform massTests;
            part vehicle_UnitUnderTest :> vehicle_b;
            part massVerificationSystem{
                part scale{
                    perform massTests.weighVehicle;
                }
                part operator{
                    perform massTests.evaluatePassFail;
                }
            }
        }
    }
}
