package VehicleAnalysis {
    import VehicleDefinitions::*;
    
    import RiskMetadata::*;
    import RiskLevelEnum::*;
    // recursive import uses double asterisk **
    import VehicleConfigurations::VehicleConfiguration_b::**;
    package FuelEconomyAnalysisModel{
        import SampledFunctions::SampledFunction;
              
        /*
          This analysis model was provided by Hisashi Miyashita on January 27, 2021
          We use the simplest fuel consumption analysis model introduced in:
          Akcelik, R. "Fuel efficiency and other objectives in traffic system management." Traffic Engineering and Control 22.2 (1981): 54-65. 

          Fuel consumption rate f can be decomposed to:
          f = f_a + f_b * tpd_avg,
          where tpd_avg is average interrupted travel time per unit distance, actually the inverse of the average velocity [t/km];
          f_a is the best fuel consumption per distance; and
          f_b is the additional fuel consumption per distance and average travel time, which can be regarded as the idling fuel consumption.
          Approximately, it is proportional to engine displacement and it ranges from 0.5 to 0.6 [l/hour/litre of engine displacement]
          according to:
          Review of the Incidence, Energy Use and Costs of Passenger Vehicle Idling; Gordon W. Taylor, P.Eng. Prepared for the Office of Energy Efficiency, Natural Resources Canada, 2003

          We assume f_a can be approximated to
          fuel_consumption / distance = BSFC * SGG * required_power_avg * tpd_avg,
          where required_power_avg is the required power, and it can be approximately derived from:
          total_energy == P_req * tpd_avg * distance == 1/2 * mass / tpd_avg^2
          This part is computed with BestFuelConsumptionPerDistance calc def.

          BSFC means Brake-Specific Fuel Consumption, defined as gram/power.  SGG is the specific gravity of gasoline.
          The high octane gasoline is about 0.76[l/kg].
        */
            
        attribute def Scenario :> SampledFunction {
            attribute wayPoint[1..*] {
                attribute elapseTime[1] :> ISQ::time;
                attribute position[1] :> ISQ::distance;
            }
        }
            
        calc def FuelConsumption {
            in bestFuelConsumption: Real;
            in idlingFuelConsumption: Real; 
            in tpd_avg:>timePerDistance;
            attribute f = bestFuelConsumption + idlingFuelConsumption * tpd_avg;
            return dpv :> distancePerVolume = 1/f;
        }
            
        calc def AverageTravelTimePerDistance {
            in scenario: Scenario;
            return tpd_avg:>timePerDistance;
        }
        calc def TraveledDistance {
            in scenario: Scenario;
            return distance:> length;
        }
        calc def IdlingFuelConsumptionPerTime {
            in engine:Engine;
            attribute idlingFuelConsumptionPerDisplacement: Real = 0.5;
            return f_a : Real = engine.displacement * idlingFuelConsumptionPerDisplacement;
        }

        attribute specificGravityOfGasoline: Real = 0.76;
        calc def BestFuelConsumptionPerDistance {
            in mass: MassValue;
            in bsfc: Real;
            in tpd_avg:> timePerDistance;
            in distance:>length;
            attribute required_power_avg:> ISQ::power;
            constraint {required_power_avg == 1/2 * mass * tpd_avg **(-3) / distance}
            return f_b : Real = bsfc * specificGravityOfGasoline * required_power_avg * tpd_avg;
        }

        calc def ComputeBSFC{
            in engine: Engine;
            return : Real;
        }

        analysis fuelEconomyAnalysis  {    
            subject = vehicle_b; 
                
            objective fuelEconomyAnalysisObjective {
                doc /*estimate the vehicle fuel economy*/
                require vehicleSpecification.vehicleFuelEconomyRequirements;
            }
                
            in attribute scenario: Scenario;
            // define a series of waypoints
                
            attribute distance = TraveledDistance(scenario);
            attribute tpd_avg = AverageTravelTimePerDistance(scenario);
            attribute bsfc = ComputeBSFC(vehicle_b.engine);
            attribute f_a = BestFuelConsumptionPerDistance(vehicle_b.mass, bsfc, tpd_avg, distance);
            attribute f_b = IdlingFuelConsumptionPerTime(vehicle_b.engine);

            return attribute calculatedFuelEconomy:>distancePerVolume=FuelConsumption(f_a, f_b, tpd_avg);
        }
    }
    package ElectricalPowerAnalysis{
    }
    package ReliabilityAnalyis{
    }
    package VehicleTradeOffAnalysis{
        /* The following example provides the rationale for selecting the engine4cyl. 
           The rationale and risk are contained in a metadata library. */
            
        @Rationale about engineTradeOffAnalysis::vehicle_b_engine4cyl{
            explanation = VehicleAnalysis::VehicleTradeOffAnalysis::engineTradeOffAnalysis;          
            text = "the engine4cyl was evaluated to have a higher objective function compared to the engine6cyl based on the trade-off analyiss"; 
        }
            
        // The following risk for the engine4cyl could have been included as part of the objective evaluaiton criteria
            
        @Risk about engineTradeOffAnalysis::vehicle_b_engine4cyl {
            totalRisk = medium;
            technicalRisk = medium;
            scheduleRisk = medium;
            costRisk = RiskLevelEnum::low;
        }
        @Risk about engineTradeOffAnalysis::vehicle_b_engine4cyl::engine::fuelEfficiency {
            technicalRisk {
                probability = 0.3;
                impact = 0.5;
            }
        }
            
                
        import TradeStudies::*;
        //evaluation function with criterion engine mass, engine power, and engine cost
        calc def EngineEvaluation {
            in engineMass:>ISQ::mass;
            in enginePower:>ISQ::power; 
            in engineFuelEfficiency:Real;
            in engineCost:Real;
            return eval:Real;
        }
        calc def EngineEvaluation_4cyl {
            in engineMass:>ISQ::mass;
            in enginePower:>ISQ::power;
            in engineFuelEfficiency:Real;
            in engineCost:Real;
            return eval:Real;
        }
        calc def EngineEvaluation_6cyl {
            in engineMass:>ISQ::mass;
            in enginePower:>ISQ::power;
            in engineFuelEfficiency:Real;
            in engineCost:Real;
            return eval:Real;
        }
        analysis engineTradeOffAnalysis:TradeStudy{
            subject vehicleAlternatives[2]:>vehicle_b;   
                
            part vehicle_b_engine4cyl:>vehicleAlternatives{   
                part engine redefines engine{
                    part cylinders :>> cylinders [4];
                    attribute mass redefines mass=180 [kg];
                    attribute peakHorsePower redefines peakHorsePower = 180 [W];
                    attribute fuelEfficiency redefines fuelEfficiency=.6;
                    attribute cost redefines cost = 1000;                     
                }
            }
            part vehicle_b_engine6cyl:>vehicleAlternatives{   
                part engine redefines engine{  
                    part cylinders redefines cylinders [6];
                    attribute mass redefines mass=220 [kg];
                    attribute peakHorsePower redefines peakHorsePower = 220 [W];
                    attribute fuelEfficiency redefines fuelEfficiency=.5;
                    attribute cost redefines cost = 1500;
                }
            }
                
            objective :MaximizeObjective;
            /*Select vehicle alternative with the engine whose evaluation function returns the max value*/
                
            calc :> evaluationFunction{
                in part vehicle:>vehicle_b_engine4cyl;
                return attribute eval:Real=EngineEvaluation_4cyl (vehicle.engine.mass, vehicle.engine.peakHorsePower, vehicle.engine.fuelEfficiency, vehicle.engine.cost); 
            }
            calc :> evaluationFunction{
                in part vehicle:>vehicle_b_engine6cyl;
                return attribute eval:Real=EngineEvaluation_6cyl (vehicle.engine.mass, vehicle.engine.peakHorsePower, vehicle.engine.fuelEfficiency, vehicle.engine.cost); 
            }                                                  
            return part selectedVehicle:>vehicle_b;
        }
    }
}
