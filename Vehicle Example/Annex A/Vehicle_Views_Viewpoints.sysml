package Vehilce_Views_Viewpoints {
    import VehicleDefinitions::MetadataDefinitions::*;
    package ViewpointDefinitions{
        viewpoint def BehaviorViewpoint;
        viewpoint def SafetyViewpoint{
            frame concern vs:VehicleSafety;
        }
        part def SafetyEngineer;
        concern def VehicleSafety {
            doc /* identify system safety features */
            stakeholder se:SafetyEngineer;
        }
    }
    package ViewDefinitions{
        //Import Views to access rendering method library 
        import Views::*;
        view def TreeView{
            render asTreeDiagram;
        }
        view def NestedView; 
        view def RelationshipView;
        view def TableView;
        view def PartsTreeView:>TreeView {
            filter @SysML::PartUsage;
        }
        view def PartsInterconnection:>NestedView;
    }
    package VehicleViews{
        import ViewpointDefinitions::*;
        import ViewDefinitions::*;
        import VehicleConfigurations::VehicleConfiguration_b::*;
        view vehiclePartsTree_Safety:PartsTreeView{
            satisfy requirement sv:SafetyViewpoint;
            expose PartsTree::**;
            filter @Safety;
        }
    }
}
